# frozen_string_literal: true

# name: discourse-indisposable-email
# about: Prevent users from using disposable email addresses
# meta_topic_id: 396730
# version: 1.0
# authors: elmuerte
# url: https://github.com/magicball-network/discourse-indisposable-email
# required_version: 2026.1

enabled_site_setting :indisposable_email_enabled

module ::DiscourseIndisposableEmail
  PLUGIN_NAME = "discourse-indisposable-email"
  HTTP_USER_AGENT =
    "#{PLUGIN_NAME}/1.0 (+https://github.com/magicball-network/discourse-indisposable-email)"
end

require_relative "lib/discourse_indisposable_email/engine"

after_initialize do
  require_relative "lib/discourse_indisposable_email/email_check"
  EmailValidator.singleton_class.prepend(
    DiscourseIndisposableEmail::EmailChecker
  )
end
