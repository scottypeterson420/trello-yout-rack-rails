require "logger"
require "uri"
require "config"
require "cache"

require "trello"
require "you_track"

class CliTool
  protected

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
