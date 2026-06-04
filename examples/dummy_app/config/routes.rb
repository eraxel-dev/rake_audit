# frozen_string_literal: true

Rails.application.routes.draw do
  # Mount the rake_audit Web UI. With the engine mounted here:
  #   /rake_audit                 → paginated execution list (root)
  #   /rake_audit/dashboard       → aggregate stats
  #   /rake_audit/executions/:id  → single execution detail
  #
  # The UI is open in this demo. To restrict it, set config.authenticate_with
  # in config/initializers/rake_audit.rb (see the commented example there).
  mount RakeAudit::Engine, at: '/rake_audit'

  # Send the app root to the dashboard so visiting http://localhost:3000/
  # lands somewhere useful.
  root to: redirect('/rake_audit/dashboard')
end
