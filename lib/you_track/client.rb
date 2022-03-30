require "basic_error"

module YouTrack
  class Client
    PROJECT_FIELDS = %w[
      id
      name
      shortName
    ].freeze

    Error = Class.new(BasicError)

    attr_reader :token, :root_url, :logger

    def initialize(token:, root_url:, logger: nil)
      @token = token
      @root_url = root_url
      @logger = logger
    end

    def get(path, params = {})
      response = connection.get(path, auth_params.merge(params))
      ensure_successful_response(response)
      JSON.parse(response.body)
    end

    def projects(fields: PROJECT_FIELDS)
      get("/api/admin/projects", fields: fields.join(","))
    end

    private

    def ensure_successful_response(response)
      return if response.success?
      raise Error.new(response: response.as_json)
    end

    def auth_params
      {token: token}
    end

    def connection
      Faraday.new(url: root_url) do |faraday|
        faraday.request(:authorization, "Bearer", token)

        # SEE: https://lostisland.github.io/faraday/middleware/logger
        faraday.response(:logger, logger) do |faraday_logger|
          faraday_logger.filter(/(token=)(\w+)/, '\1[REMOVED]')
        end

        faraday.adapter(Faraday.default_adapter)
      end
    end
  end
end
