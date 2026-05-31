# frozen_string_literal: true

# RakeAudit configuration.
#
# Every option below is shown with its default and left commented out. Uncomment
# and edit the lines you want to override. At minimum, set an adapter to enable
# recording — without one, RakeAudit loads but records nothing.
RakeAudit.configure do |config|
  # config.adapter = RakeAudit::Adapters::ActiveRecordAdapter.new
  # config.logger  = Rails.logger
  # config.capture_hostname     = true
  # config.capture_pid          = true
  # config.capture_ruby_version = true
  # config.capture_rails_env    = true
  # config.web_ui_enabled       = true
  # config.authenticate_with    = ->(controller) { controller.authenticate_admin! }
end
