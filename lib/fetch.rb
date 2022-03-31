require "logger"
require "uri"
require "config"

require "trello"
require "you_track"

class Fetch
  def run
    cache("youtrack_projects.json") { youtrack.projects }
    cache("youtrack_users.json") { youtrack.users }
    cache("youtrack_tags.json") { youtrack.tags }
    cache("trello_organization_boards.json") { trello_organization_boards }

    read_cache("trello_organization_boards.json").each do |board|
      board_id = board["id"]
      cache("trello_board_labels/#{board_id}.json") { trello.board_labels(board_id: board_id) }
      cache("trello_board_members/#{board_id}.json") { trello.board_members(board_id: board_id) }
    end

    puts JSON.pretty_generate(trello.member(member_id: "58fee3bdaddf79720c126f22"))

    # TODO: Trello users
    # TODO: Generate mapping configuration file JSON
    # Trello user → YT user
    # Trello label → YT label
    # Generate YT labels

    # TODO: Idempotent import
    # comment original Trello task with YT task reference
    # log imported task with Trello card id and YT task id
  end

  private

  def read_cache(file_name)
    JSON.parse(File.read(cache_path(file_name)))
  end

  def cache(file_name)
    full_path = cache_path(file_name)
    return if File.exist?(full_path)
    logger.info("updating #{full_path}")
    FileUtils.mkdir_p(File.dirname(full_path))
    yield.tap { File.write(full_path, JSON.pretty_generate(_1)) }
  end

  def cache_path(file_name)
    File.join(Dir.pwd, "out", file_name)
  end

  def trello_organization_boards
    trello.organization_boards(organization_id: trello_organization_id)
  end

  def trello_organization_id
    organizations = trello.organizations
    organization = organizations.find { _1["name"] == Config.trello_organization_name }
    organization.fetch("id")
  end

  def youtrack
    @youtrack ||= YouTrack::Client.new(
      token: Config.youtrack_api_token,
      root_url: Config.youtrack_root_url,
      logger: logger
    )
  end

  def trello
    @trello ||= Trello::Client.new(
      key: Config.trello_api_key,
      token: Config.trello_api_token,
      logger: logger
    )
  end

  def logger
    @logger ||= build_logger
  end

  def build_logger
    Logger.new(Config.debug? ? $stdout : IO::NULL).tap do |logger|
      logger.formatter = proc do |severity, datetime, progname, msg|
        "[#{severity}] #{msg}\n"
      end
    end
  end
end
