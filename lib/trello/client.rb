require "trello/filter"

module Trello
  class Client
    BASE_URL = "https://api.trello.com"

    ORGANIZATION_INDEX_FIELDS = %w[
      id
      name
      displayName
      idBoards
      url
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
      dateLastActivity
      dateLastView
      desc
      descData
      idMemberCreator
      idOrganization
      invitations
      invited
      labelNames
      memberships
      name
      pinned
      powerUps
      prefs
      shortLink
      shortUrl
      starred
      subscribed
      url
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
    ].join(",")

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
    ].join(",")

    Error = Class.new(BasicError)

    attr_reader :key, :token, :logger

    def initialize(key: nil, token: nil, logger: nil)
      @key = key
      @token = token
    end

    def get(path, params = {})
      response = connection.get(path, auth_params.merge(params))
      ensure_successful_response(response)
      JSON.parse(response.body)
    end

    def boards(fields: BOARD_INDEX_FIELDS)
      get("/1/members/me/boards", fields: fields.join(","))
    end

    def organizations(fields: ORGANIZATION_INDEX_FIELDS)
      get("/1/members/me/organizations", fields: fields)
    end

    def organization_boards(organization_id, filter: Trello::Filter::ALL)
      get("1/organizations/#{organization_id}/boards", filter: filter)
    end

    def board(board_id, fields: BOARD_FIELDS)
      get("/1/boards/#{board_id}", fields: fields)
    end

    # SEE: https://developer.atlassian.com/cloud/trello/rest/api-group-boards/#api-boards-id-lists-get
    def board_lists(board_id, filter: Trello::Filter::ALL)
      get("1/boards/#{board_id}/lists", filter: filter)
    end

    def list(list_id)
      get("/1/lists/#{list_id}")
    end

    def board_cards(board_id, fields: CARD_INDEX_FIELDS)
      get("/1/boards/#{board_id}/cards/all", fields: fields)
    end

    def card(card_id, fields: CARD_FIELDS)
      get("/1/cards/#{card_id}", fields: fields)
    end

    private

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
        faraday.response(:logger, logger) do |faraday_logger|
          faraday_logger.filter(/(token=)(\w+)/, '\1[REMOVED]')
        end

        faraday.adapter(Faraday.default_adapter)
      end
    end
  end
end
