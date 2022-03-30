require "logger"
require "uri"
require "config"

require "you_track/client"

class Main
  def run
    puts JSON.pretty_generate(youtrack.projects)
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
