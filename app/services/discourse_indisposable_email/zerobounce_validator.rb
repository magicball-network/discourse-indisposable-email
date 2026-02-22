# frozen_string_literal: true

require "uri"
require "net/http"

module DiscourseIndisposableEmail
  # API specification: https://www.zerobounce.net/docs/email-validation-api-quickstart/v2-validate-emails
  class ZerobounceValidator < EmailAddressValidator
    def validator_id
      "zerobounce"
    end

    def enabled?
      SiteSetting.indisposable_email_zerobounce_key.present? && !backoff?
    end

    def retrieve_status(domain)
      uri = URI("https://api-eu.zerobounce.net/v2/validate")
      request = {
        email: "example@#{domain}",
        api_key: SiteSetting.indisposable_email_zerobounce_key
      }
      uri.query = URI.encode_www_form(request)
      headers = { "User-Agent" => HTTP_USER_AGENT }

      response = Net::HTTP.get_response(uri, headers)
      unless response.code == "200"
        handle_failure(response)
        return :failure
      end

      puts response.body

      json = JSON.parse(response.body)
      if json["error"]
        @backoff_until = Time.now + 5.minutes
        Rails.logger.warn "Communication failure with zerobounce. #{json["error"]}"
        return :failure
      end

      json["sub_status"] == "disposable" ? :deny : :allow
    rescue StandardError => error
      Rails.logger.warn "Communication failure with zerobounce. #{error.message}",
                        error
      :failure
    end
  end
end
