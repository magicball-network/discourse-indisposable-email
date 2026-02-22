# frozen_string_literal: true
module DiscourseIndisposableEmail
  class EmailAddressValidator
    def allowed_address?(email)
      domain = get_domain(email)
      return :failure if domain.blank?
      domain_status?(domain)
    end

    def validator_id
      "abstract-class"
    end

    def enabled?
      false
    end

    def retrieve_status(domain)
      :failure
    end

    def get_domain(email)
      return "" if email.nil?
      parts = email.split("@")
      return "" if parts.nil? || parts.length != 2
      parts.last.downcase
    end

    def domain_status?(domain)
      key = create_cache_key(domain)
      cached = (Discourse.cache.read(key) || "unknown").to_sym
      return cached if cached == :allow || cached == :deny

      value = retrieve_status(domain)
      if value != :failure
        update_cache(key, value)
        update_site_settings(domain) if value == :deny
      end
      value
    end

    def create_cache_key(domain)
      "DIE::#{domain.downcase}"
    end

    def update_cache(key, status)
      if status == :deny
        ttl = SiteSetting.indisposable_email_deny_cache
      else
        ttl = SiteSetting.indisposable_email_allow_cache
      end
      Discourse.cache.write(key, status) if ttl > 0
    end

    def update_site_settings(domain)
      return unless SiteSetting.indisposable_email_update_blocked_domains
      return if SiteSetting.blocked_email_domains.split("|").include?(domain)
      SiteSetting.blocked_email_domains =
        SiteSetting.blocked_email_domains + "|" + domain
    end

    def backoff?
      @backoff_until && @backoff_until.future?
    end

    def handle_failure(response)
      @backoff_until = Time.now + 5.minutes if response.code == "429"
      Rails.logger.warn "Communication failure with #{self.validator_id}. #{response.code}"
    end
  end
end
