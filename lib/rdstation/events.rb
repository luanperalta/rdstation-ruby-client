module RDStation
  class Events
    include HTTParty
    include ::RDStation::RetryableRequest

    EVENTS_ENDPOINT = 'https://api.rd.services/platform/events'.freeze

    def initialize(authorization:)
      @authorization = authorization
    end

    def create(payload)
      retryable_request(@authorization) do |authorization|
        response = self.class.post(EVENTS_ENDPOINT, headers: authorization.headers, body: payload.to_json)
        response_body = JSON.parse(response.body)
        return response_body unless errors?(response_body)
        RDStation::ErrorHandler.new(response).raise_error
      end
    end

    private

    def errors?(response_body)
      response_body.is_a?(Array) || response_body['errors']
    end
  end
end
