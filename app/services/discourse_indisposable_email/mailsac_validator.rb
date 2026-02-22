# frozen_string_literal: true

require "uri"
require "net/http"

module DiscourseIndisposableEmail
  # API specification: https://mailsac.com/docs/api#tag/emailValidation/operation/ValidateAddress
  class MailsacValidator < EmailAddressValidator
    def validator_id
      "mailsac"
    end

    def enabled?
      SiteSetting.indisposable_email_mailsac_key.present? && !backoff?
    end

    def retrieve_status(domain)
      uri =
        URI("https://mailsac.com/api/validations/addresses/example@#{domain}")
      headers = {
        "Mailsac-Key" => SiteSetting.indisposable_email_mailsac_key,
        "User-Agent" => HTTP_USER_AGENT
      }

      response = Net::HTTP.get_response(uri, headers)
      unless response.code == "200"
        handle_failure(response)
        return :failure
      end

      json = JSON.parse(response.body)

      json["isDisposable"] ? :deny : :allow
    rescue StandardError => error
      Rails.logger.warn("Communication failure with mailsac. #{error.message}")
      :failure
    end
  end
end
