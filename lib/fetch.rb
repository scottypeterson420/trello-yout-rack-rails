require "logger"
require "uri"
require "config"
require "cache"

require "trello"
require "you_track"

class Fetch
  def run
    fetch("youtrack_projects") { youtrack.projects }
    fetch("youtrack_users") { youtrack.users }
    fetch("youtrack_tags") { youtrack.tags }
    fetch("trello_organization_boards") { trello_organization_boards }

    fetch("trello_organization_boards").each do |board|
      board_id = board["id"]
      fetch("trello_board_labels/#{board_id}") { trello.board_labels(board_id: board_id) }
      fetch("trello_board_members/#{board_id}") { trello.board_members(board_id: board_id) }
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

  def fetch(key, &block)
    cache.fetch(key, &block)
  end

  def cache
    @cache ||= Cache.new(path: File.join(Dir.pwd, "cache"), logger: logger)
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
