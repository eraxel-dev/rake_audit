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
  end
end
