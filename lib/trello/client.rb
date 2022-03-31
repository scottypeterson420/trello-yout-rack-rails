require "basic_error"
require "trello/filter"

module Trello
  class Client
    ORGANIZATION_INDEX_FIELDS = %w[
      id
      name
    ].freeze

    # SEE: https://developer.atlassian.com/cloud/trello/rest/api-group-boards/#api-boards-id-field-get
    BOARD_INDEX_FIELDS = %w[
      id
      closed
      idMemberCreator
      idOrganization
      name
      url
    ].freeze

    # SEE: https://developer.atlassian.com/cloud/trello/rest/api-group-boards/#api-boards-id-field-get
    BOARD_FIELDS = %w[
      closed
      name
    ].freeze

    # SEE: https://developer.atlassian.com/cloud/trello/rest/#api-boards-id-cards-get
    CARD_INDEX_FIELDS = %w[
      id
      idBoard
      idLabels
      idList
      labels
      name
      shortUrl
      closed
    ].freeze

    # SEE: https://developer.atlassian.com/cloud/trello/rest/api-group-cards/#api-cards-id-get
    CARD_FIELDS = %w[
      badges
      checkItemStates
      closed
      dateLastActivity
      desc
      descData
      due
      email
      idBoard
      idChecklists
      idLabels
      idList
      idMembers
      idShort
      idAttachmentCover
      manualCoverAttachment
      labels
      name
      pos
      shortUrl
      url
    ].freeze

    Error = Class.new(BasicError)

    attr_reader :key, :token, :logger

    def initialize(key:, token:, logger:)
      @key = key
      @token = token
      @logger = logger
    end

    def get(path, params = {})
      response = connection.get(path, auth_params.merge(params))
      ensure_successful_response(response)
      JSON.parse(response.body)
    end

    def boards(fields: BOARD_INDEX_FIELDS)
      get("/1/members/me/boards", fields: csv(fields))
    end

    # SEE: https://developer.atlassian.com/cloud/trello/rest/api-group-boards/#api-boards-id-labels-get=
    def board_labels(board_id:, limit: 200)
      get("/1/boards/#{board_id}/labels", limit: limit)
    end

    # SEE: https://developer.atlassian.com/cloud/trello/rest/api-group-boards/#api-boards-id-members-get=
    def board_members(board_id:)
      get("/1/boards/#{board_id}/members")
    end

    def member(member_id:)
      get("/1/members/#{member_id}")
    end

    def organizations(fields: ORGANIZATION_INDEX_FIELDS)
      get("/1/members/me/organizations", fields: csv(fields))
    end

    def organization_boards(organization_id:, fields: BOARD_FIELDS)
      get("/1/organizations/#{organization_id}/boards", fields: csv(fields))
    end

    # SEE: https://developer.atlassian.com/cloud/trello/rest/api-group-organizations/#api-organizations-id-boards-get=
    def board(board_id, fields: BOARD_FIELDS)
      get("/1/boards/#{board_id}", fields: csv(fields))
    end

    # SEE: https://developer.atlassian.com/cloud/trello/rest/api-group-boards/#api-boards-id-lists-get
    def board_lists(board_id, filter: Trello::Filter::ALL)
      get("1/boards/#{board_id}/lists", filter: filter)
    end

    def list(list_id)
      get("/1/lists/#{list_id}")
    end

    def board_cards(board_id, fields: CARD_INDEX_FIELDS)
      get("/1/boards/#{board_id}/cards/all", fields: csv(fields))
    end

    def card(card_id, fields: CARD_FIELDS)
      get("/1/cards/#{card_id}", fields: csv(fields))
    end

    private

    def csv(values)
      values.join(",")
    end

    def ensure_successful_response(response)
      return if response.success?
      raise Error.new(response: response.as_json)
    end

    def auth_params
      @auth_params ||= {
        key: key || ENV.fetch("TRELLO_API_KEY"),
        token: token || ENV.fetch("TRELLO_API_TOKEN")
      }
    end

    def connection
      Faraday.new(url: Trello::BASE_URL) do |faraday|
        # SEE: https://lostisland.github.io/faraday/middleware/logger
        faraday.response(:logger, logger, {headers: false, bodies: true}) do |faraday_logger|
          faraday_logger.filter(/(token=)(\w+)/, '\1[REMOVED]')
        end

        faraday.adapter(Faraday.default_adapter)
      end
    end
  end
end
