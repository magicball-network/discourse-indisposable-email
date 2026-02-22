# frozen_string_literal: true

require "uri"
require "net/http"

module DiscourseIndisposableEmail
  # API specification: https://www.usercheck.com/docs/api/domain-endpoint
  class UsercheckValidator < EmailAddressValidator
    def validator_id
      "usercheck"
    end

    def enabled?
      SiteSetting.indisposable_email_usercheck_key.present? && !backoff?
    end

    def retrieve_status(domain)
      uri = URI("https://api.usercheck.com/domain/#{domain}")
      headers = {
        "Authorization" =>
          "Bearer #{SiteSetting.indisposable_email_usercheck_key}",
        "User-Agent" => HTTP_USER_AGENT
      }

      response = Net::HTTP.get_response(uri, headers)
      unless response.code == "200"
        handle_failure(response)
        return :failure
      end

      json = JSON.parse(response.body)

      @backoff_until = Time.now + 1.second

      json["disposable"] ? :deny : :allow
    rescue StandardError => error
      Rails.logger.warn(
        "Communication failure with usercheck. #{error.message}"
      )
      :failure
    end
  end
end
