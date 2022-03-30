require "basic_error"

module YouTrack
  class Client
    # SEE: https://www.jetbrains.com/help/youtrack/devportal/resource-api-admin-projects.html
    PROJECT_FIELDS = %w[
      id
      name
      shortName
    ].freeze

    # SEE: https://www.jetbrains.com/help/youtrack/devportal/api-entity-User.html
    USER_FIELDS = %w[
      id
      login
      fullName
      email
    ].freeze

    # SEE: https://www.jetbrains.com/help/youtrack/devportal/resource-api-issueTags.html#IssueTag-supported-fields
    TAG_FIELDS = %w[
      id
      name
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
      omit_type_field(get("/api/admin/projects", fields: csv(fields)))
    end

    # NOTE: Pagination is not implemented; assuming full users list
    # will fit in a single response
    def users(fields: USER_FIELDS)
      omit_type_field(get("/api/users", fields: csv(fields)))
    end

    def tags(fields: TAG_FIELDS)
      omit_type_field(get("/api/issueTags", fields: csv(fields)))
    end

    private

    def omit_type_field(objects)
      objects.map { _1.except("$type") }
    end

    def csv(values)
      values.join(",")
    end

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
