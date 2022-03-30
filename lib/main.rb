require "logger"
require "uri"
require "config"

require "you_track/client"

class Main
  def run
    puts JSON.pretty_generate(youtrack.projects)
    puts JSON.pretty_generate(youtrack.users)
    puts JSON.pretty_generate(youtrack.tags)

    # TODO: Trello boards
    # TODO: Trello users
    # TODO: Trello labels

    # TODO: Generate mapping configuration file JSON

    # TODO: Idempotent import
  end

  private

  def youtrack
    @youtrack ||= YouTrack::Client.new(
      token: Config.youtrack_api_token,
      root_url: Config.youtrack_root_url,
      logger: logger
    )
  end

  def logger
    @logger ||= Logger.new(Config.debug? ? $stdout : IO::NULL)
  end
end
