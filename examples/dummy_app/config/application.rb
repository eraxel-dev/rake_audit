# frozen_string_literal: true

require_relative 'boot'

# Load only the Rails frameworks this example needs. ActiveRecord backs the
# audit table; ActionController + ActionView render the mounted Web UI. We
# deliberately skip ActiveJob, ActionMailer, ActionCable, etc. to keep the
# example minimal and easy to read.
require 'rails'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

# Require the gems listed in Gemfile, including rake_audit (path: '../..').
Bundler.require(*Rails.groups)

module DummyApp
  # Host application that demonstrates integrating rake_audit.
  class Application < Rails::Application
    config.load_defaults 7.0

    # This is a deliberately slim demo app: no asset pipeline, no generators
    # beyond what's checked in. Eager loading stays off in development.
    config.eager_load = false

    # Quiet the "add secret_key_base" prompt for this throwaway demo. In a real
    # app this comes from credentials or ENV.
    config.secret_key_base = 'rake_audit_dummy_app_demo_secret_key_base_change_me'
  end
end
