class Config
  def self.debug?
    ENV.key?("DEBUG")
  end

  def self.youtrack_root_url
    ENV.fetch("YOUTRACK_ROOT_URL")
  end

  def self.youtrack_api_token
    ENV.fetch("YOUTRACK_API_TOKEN")
  end

  def self.trello_api_key
    ENV.fetch("TRELLO_API_KEY")
  end

  def self.trello_api_token
    ENV.fetch("TRELLO_API_TOKEN")
  end

  def self.trello_organization_name
    ENV.fetch("TRELLO_ORGANIZATION_NAME")
  end
end
