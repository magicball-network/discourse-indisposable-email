# frozen_string_literal: true
module DiscourseIndisposableEmail
  class EmailAddressValidator
    def allowed_address?(email)
      domain = get_domain(email)
      return :failure if domain.blank?
      domain_status?(domain)
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
        Discourse.cache.write(key, value)
        update_site_settings(domain)
      end
      value
    end

    def create_cache_key(domain)
      "DIE::#{domain.downcase}"
    end

    def update_site_settings(domain)
      # TODO
    end
  end
end
