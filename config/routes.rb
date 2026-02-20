# frozen_string_literal: true

DiscourseIndisposableEmail::Engine.routes.draw do
  get "debug" => "debug#index", :constraints => AdminConstraint.new
end

Discourse::Application.routes.draw do
  mount ::DiscourseIndisposableEmail::Engine, at: "/indisposable-email"
end
