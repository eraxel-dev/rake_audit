# frozen_string_literal: true

module RakeAudit
  # Base controller for every RakeAudit Web UI page.
  #
  # It installs the pluggable authentication hook as a +before_action+. When the
  # host application has configured {RakeAudit::Configuration#authenticate_with}
  # with a callable, that callable is run in the controller instance's context on
  # every request (so it may call host helpers such as +authenticate_admin!+ or
  # +redirect_to+). When +authenticate_with+ is +nil+, the hook is a no-op and
  # all pages are publicly accessible.
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    before_action :authenticate!
    rescue_from RakeAudit::RecordNotFound, with: :record_not_found

    private

    # Run the configured authentication callable, if any, in the context of this
    # controller instance. The controller is also passed as the block argument so
    # procs may be written as +->(controller) { ... }+ or use +self+ directly.
    #
    # @return [void]
    def authenticate!
      callable = RakeAudit.config.authenticate_with
      return unless callable

      instance_exec(self, &callable)
    end

    # Returns the configured adapter. Falls back to a fresh ActiveRecordAdapter
    # when none is set so existing apps keep working without explicit configuration.
    #
    # @return [RakeAudit::Adapters::Base]
    def web_adapter
      RakeAudit.config.adapter || default_web_adapter
    end

    def default_web_adapter
      require 'rake_audit/adapters/active_record_adapter'
      RakeAudit.config.logger.warn(
        '[RakeAudit] config.adapter is nil — falling back to ActiveRecordAdapter. ' \
        'Set RakeAudit.configure { |c| c.adapter = ... } in your initializer to silence this warning.'
      )
      RakeAudit::Adapters::ActiveRecordAdapter.new
    end

    def record_not_found
      head :not_found
    end
  end
end
