# frozen_string_literal: true

require "uri"
require "net/http"

module DiscourseIndisposableEmail
  # API specification: https://www.usercheck.com/docs/api/domain-endpoint
  class UsercheckValidator < EmailAddressValidator
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

      # TODO make this configurable for better plans
      @backoff_until = DateTime.now + 2.seconds

      json["disposable"] ? :deny : :allow
    rescue StandardError => error
      Rails.logger.warn "Communication failure with usercheck. #{error.message}",
                        error
      :failure
    end

    def backoff?
      @backoff_until && @backoff_until.future?
    end

    def handle_failure(response)
      @backoff_until = DateTime.now + 5.minutes if response.code == "429"
      Rails.logger.warn "Communication failure with usercheck. #{response.code}"
    end
  end
end
