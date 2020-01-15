# frozen_string_literal: true

module RDStation
  module RetryableRequest
    MAX_RETRIES = 1
    def retryable_request(authorization)
      retries = 0
      begin
        yield authorization
      rescue ::RDStation::Error::ExpiredAccessToken => e
        raise if !retry_possible?(authorization) || retries >= MAX_RETRIES

        retries += 1
        refresh_access_token(authorization)
        retry
      end
    end

    def retry_possible?(authorization)
      unless RDStation.configuration.nil?
        [
          RDStation.configuration.client_id,
          RDStation.configuration.client_secret,
          authorization.refresh_token
        ].all?
      else
        false
      end
    end

    def refresh_access_token(authorization)
      client = RDStation::Authentication.new
      response = client.update_access_token(authorization.refresh_token)
      authorization.access_token = response['access_token']
      authorization.access_token_expires_in = response['expires_in']
      #RDStation.configuration&.access_token_refresh_callback&.call(authorization)
      RDStation.configuration.access_token_refresh_callback.call(authorization) if !RDStation.configuration.nil? && !RDStation.configuration.access_token_refresh_callback.nil?
    end
  end
end
