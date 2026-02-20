# frozen_string_literal: true

module DiscourseIndisposableEmail
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseIndisposableEmail
  end
end
