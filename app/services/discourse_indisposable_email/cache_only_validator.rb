# frozen_string_literal: true

module DiscourseIndisposableEmail
  # Does no actual validator, just allow the common cached value to be used
  class CacheOnlyValidator < EmailAddressValidator
    def enabled?
      true
    end
  end
end
