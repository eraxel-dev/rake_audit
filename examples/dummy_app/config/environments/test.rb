# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  # The test environment is used to boot the app under `bin/rails runner` for
  # the example's smoke checks without touching the development database.
  config.cache_classes = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store
  config.action_dispatch.show_exceptions = false
  config.active_support.deprecation = :stderr
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []
end
