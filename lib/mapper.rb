require "cli_tool"

class Mapper < CliTool
  def run
    generate_trello_member_to_youtrack_user_mapping
    generate_trello_board_to_youtrack_project_mapping
    generate_trello_labels_to_youtrack_mapping
  end

  private

  def generate_trello_member_to_youtrack_user_mapping
    generate("trello_member_to_youtrack_user") do
      mapping = {}

      fetch("trello_members").each do |member_id, member|
        mapping[member_id] = {trello_member: member, youtrack_user: {}}
      end

      mapping
    end
  end

  def generate_trello_board_to_youtrack_project_mapping
    generate("trello_board_to_youtrack_project") do
      mapping = {}

      fetch("trello_organization_boards").each do |board|
        next if board["closed"]
        board_id = board["id"]
        mapping[board_id] = board.except("closed")
        mapping[board_id]["youtrack_project"] = {}
      end

      mapping
    end
  end

  def generate_trello_labels_to_youtrack_mapping
    generate("trello_labels_to_youtrack") do
      mapping = {}

      fetch("trello_organization_boards").each do |board|
        next if board["closed"]
        board_id = board["id"]

        fetch("trello_board_labels/#{board_id}").each do |label|
          next if label["name"].empty?
          label_id = label["id"]
          mapping[label_id] = label.except("color", "idBoard").merge(youtrack_label: {})
        end
      end

      mapping
    end
  end

  def generate(key)
    file_name = File.join(generated_data_path, "#{key}.json")
    FileUtils.mkdir_p(File.dirname(file_name))
    File.write(file_name, JSON.pretty_generate(yield))
  end

  def generated_data_path
    @generated_data_path ||= File.join(Dir.pwd, "draft_mapping")
  end
end
