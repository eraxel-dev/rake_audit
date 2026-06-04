# frozen_string_literal: true

# Host application controller. The rake_audit Web UI lives entirely inside the
# mounted engine (RakeAudit::ApplicationController), so this app-level
# controller is intentionally empty — it exists only to satisfy Rails
# conventions for the host application.
class ApplicationController < ActionController::Base
end
