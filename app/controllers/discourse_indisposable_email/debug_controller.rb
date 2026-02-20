# frozen_string_literal: true

module DiscourseIndisposableEmail
  class DebugController < ::Admin::AdminController
    requires_plugin PLUGIN_NAME

    skip_before_action :check_xhr,
                       :redirect_to_login_if_required,
                       :redirect_to_profile_if_required,
                       :verify_authenticity_token

    layout false

    def index
      invalidate_cache(params[:email]) if params[:invalidateCache]
      result = ValidationService.allowed?(params[:email])
      render plain: "Allowed?: #{result}"
    end

    private

    def invalidate_cache(email)
      return if email.nil?
      parts = email.split("@")
      return if parts.nil? || parts.length != 2
      domain = parts.last.downcase
      key = "DIE::#{domain}"
      Discourse.cache.delete(key)
    end
  end
end
