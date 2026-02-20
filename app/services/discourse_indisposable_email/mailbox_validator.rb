# frozen_string_literal: true

require "uri"
require "net/http"

module DiscourseIndisposableEmail
  # API specification: https://www.mailboxvalidator.com/api-email-disposable
  class MailboxValidator < EmailAddressValidator
    def enabled?
      SiteSetting.indisposable_email_mailboxvalidator_key.present? && !backoff?
    end

    def retrieve_status(domain)
      uri = URI("https://api.mailboxvalidator.com/v2/email/disposable")
      request = {
        email: "example@#{domain}",
        key: SiteSetting.indisposable_email_mailboxvalidator_key,
        format: "json"
      }
      uri.query = URI.encode_www_form(request)
      headers = { "User-Agent" => HTTP_USER_AGENT }

      response = Net::HTTP.get_response(uri, headers)
      json = JSON.parse(response.body || "{}")

      unless response.code == "200"
        handle_failure(json)
        return :failure
      end

      json["is_disposable"] ? :deny : :allow
    rescue StandardError => error
      Rails.logger.warn "Communication failure with mailboxvalidator. #{error.message}",
                        error
      :failure
    end

    def backoff?
      @backoff_until && @backoff_until.future?
    end

    def handle_failure(body)
      Rails.logger.warn "mailboxvalidator API call unsuccessful. #{body}"
      if body.error && body.error.error_code
        if body.error.error_code == 10_004
          # 10004 	Insufficient credits.
          @backoff_until = DateTime.now + 1.hour
        elsif body.error.error_code >= 10_001 && body.error.error_code <= 10_003
          # 10001 	API key not found.
          # 10002 	API key disabled.
          # 10003 	API key expired.
          Rails.logger.error "mailboxvalidator API key invalid"
          @backoff_until = DateTime.now + 1.minute
        end
      end
    end
  end
end
