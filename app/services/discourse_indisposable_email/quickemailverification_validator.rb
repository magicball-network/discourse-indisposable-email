# frozen_string_literal: true

require "uri"
require "net/http"

module DiscourseIndisposableEmail
  # API specification: https://docs.quickemailverification.com/email-verification-api/verify-an-email-address
  class QuickemailverificationValidator < EmailAddressValidator
    def enabled?
      SiteSetting.indisposable_email_qev_key.present? && !backoff?
    end

    def retrieve_status(domain)
      uri = URI("https://api.quickemailverification.com/v1/verify")
      request = {
        email: "example@#{domain}",
        apikey: SiteSetting.indisposable_email_qev_key
      }
      uri.query = URI.encode_www_form(request)
      headers = { "User-Agent" => HTTP_USER_AGENT }

      response = Net::HTTP.get_response(uri, headers)
      unless response.code == "200"
        handle_failure(response)
        return :failure
      end

      json = JSON.parse(response.body)

      @backoff_until = Time.now + 1.hour if response.header[
        "X-QEV-Remaining-Credits"
      ] == "0"

      json["disposable"] ? :deny : :allow
    rescue StandardError => error
      Rails.logger.warn "Communication failure with quickemailverification. #{error.message}",
                        error
      :failure
    end

    def backoff?
      @backoff_until && @backoff_until.future?
    end

    def handle_failure(response)
      @backoff_until = Time.now + 5.minutes if response.code == "429"
      Rails.logger.warn "Communication failure with quickemailverification. #{response.code}"
    end
  end
end
