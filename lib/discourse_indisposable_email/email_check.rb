# frozen_string_literal: true
module DiscourseIndisposableEmail
  module EmailChecker
    def allowed?(email)
      return false unless super(email)
      ::DiscourseIndisposableEmail::ValidationService.allowed?(email)
    end
  end
end
