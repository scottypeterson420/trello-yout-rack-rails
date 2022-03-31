class Cache
  attr_reader :path, :logger

  def initialize(path:, logger: nil)
    @path = path
    @logger = logger
  end

  def fetch(key)
    file_name = cache_path(key)
    if File.exist?(file_name)
      log("reusing #{key}")
      return JSON.parse(File.read(file_name))
    end
    log("fetching #{key}")
    FileUtils.mkdir_p(File.dirname(file_name))
    yield.tap { File.write(file_name, JSON.pretty_generate(_1)) }
  end

  private

  def log(message)
    logger&.info(message)
  end

  def cache_path(key)
    File.join(path, "#{key}.json")
  end
end
