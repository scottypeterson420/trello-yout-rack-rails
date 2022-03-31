require "cli_tool"

class Fetcher < CliTool
  def run
    fetch("youtrack_projects") { youtrack.projects }
    fetch("youtrack_users") { youtrack.users }
    fetch("youtrack_tags") { youtrack.tags }
    fetch("trello_organization_boards") { trello_organization_boards }
    fetch_trello_organization_boards
    fetch_trello_members
  end

  private

  def fetch_trello_organization_boards
    fetch("trello_organization_boards").each do |board|
      board_id = board["id"]
      fetch("trello_board_labels/#{board_id}") { trello.board_labels(board_id: board_id) }
    end
  end

  def fetch_trello_members
    fetch("trello_members") do
      trello_members = {}

      fetch("trello_organization_boards").each do |board|
        board_id = board["id"]
        board_members = fetch("trello_board_members/#{board_id}") { trello.board_members(board_id: board_id) }
        board_members.each { trello_members[_1["id"]] = _1 }
      end

      trello_members
    end
  end

  def trello_organization_boards
    trello.organization_boards(organization_id: trello_organization_id)
  end

  def trello_organization_id
    organizations = trello.organizations
    organization = organizations.find { _1["name"] == Config.trello_organization_name }
    organization.fetch("id")
  end
end
