# frozen_string_literal: true

# rake_audit configuration for this example app.
#
# IMPORTANT: rake_audit does NOT auto-require its storage adapters, so we must
# require the ActiveRecord adapter explicitly before referencing the class.
# Without this require, the line below raises NameError on boot.
require 'rake_audit/adapters/active_record_adapter'

RakeAudit.configure do |config|
  # Setting an adapter is what actually enables recording: the Railtie only
  # prepends the Rake::Task#execute hook (in config.after_initialize) when an
  # adapter is present. Leave this unset and rake_audit loads but records nothing.
  config.adapter = RakeAudit::Adapters::ActiveRecordAdapter.new

  # The fields below are captured by default; shown here for discoverability.
  # config.capture_hostname     = true
  # config.capture_pid          = true
  # config.capture_ruby_version = true
  # config.capture_rails_env    = true

  # The Web UI is enabled by default and mounted in config/routes.rb.
  # config.web_ui_enabled = true

  # The Web UI is open in this demo. To restrict it, point authenticate_with at
  # a callable that runs in the controller instance's context, e.g.:
  #   config.authenticate_with = ->(controller) { controller.authenticate_admin! }
end
