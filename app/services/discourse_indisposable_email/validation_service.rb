# frozen_string_literal: true
module DiscourseIndisposableEmail
  class ValidationService
    @@validators = [
      CacheOnlyValidator.new,
      MailboxValidator.new,
      UsercheckValidator.new,
      MailsacValidator.new,
      QuickemailverificationValidator.new,
      VerifymailValidator.new,
      ZerobounceValidator.new
    ]

    def self.allowed?(email)
      return true unless SiteSetting.indisposable_email_enabled

      result = :failure
      available = self.available_validators

      while result == :failure
        # No more available, just allow it
        if available.empty?
          Rails.logger.info(
            "Exhausted disposable email validators when checking: #{email}"
          )
          return true
        end

        validator = available.delete(available.sample)
        result = validator.allowed_address?(email)

        break if result != :failure
      end

      Rails.logger.info(
        "Disposable email validation result for #{email}: #{result}"
      )
      result == :allow
    end

    def self.available_validators
      @@validators.filter { |v| v.enabled? }
    end

    def self.validators
      @@validators
    end
    def self.validators=(value)
      @@validators = value
    end
  end
end
