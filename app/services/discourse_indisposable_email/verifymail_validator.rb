# frozen_string_literal: true

require "uri"
require "net/http"

module DiscourseIndisposableEmail
  # API specification: https://verifymail.io/api-documentation
  class VerifymailValidator < EmailAddressValidator
    def validator_id
      "verifymail"
    end

    def enabled?
      SiteSetting.indisposable_email_verifymail_key.present? && !backoff?
    end

    def retrieve_status(domain)
      uri = URI("https://verifymail.io/api/example@#{domain}")
      request = { key: SiteSetting.indisposable_email_verifymail_key }
      uri.query = URI.encode_www_form(request)
      headers = { "User-Agent" => HTTP_USER_AGENT }

      response = Net::HTTP.get_response(uri, headers)
      unless response.code == "200"
        handle_failure(response)
        return :failure
      end

      json = JSON.parse(response.body)

      json["disposable"] ? :deny : :allow
    rescue StandardError => error
      Rails.logger.warn(
        "Communication failure with verifymail. #{error.message}"
      )
      :failure
    end
  end
end
