# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  # In development we want fast feedback and verbose errors.
  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  # No caching by default.
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Raise on bad ActiveRecord usage so problems surface immediately.
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []
end
