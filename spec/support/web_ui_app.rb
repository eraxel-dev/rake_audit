# frozen_string_literal: true

# Boot a minimal Rails application that mounts the RakeAudit Engine so the Web UI
# (routes, controllers, views, pagination, authentication) can be driven end to
# end over Rack in the request specs.
#
# This deliberately avoids depending on the full +rails+ meta-gem: it wires up
# only the pieces the Web UI needs (Action Pack/View on top of the Active Record
# environment already established by +support/active_record.rb+) plus Kaminari.
# Loading is guarded so the rest of the suite still runs when these libraries are
# unavailable.

require 'logger'
require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'kaminari'

# The Engine and the gem's app/ code must be loaded before the dummy app's
# routes reference them.
require_relative '../../lib/rake_audit/rails/engine'
require_relative '../../app/models/rake_audit/task_execution'

# Give the dummy app its own throwaway root so Rails does not scan the gem's own
# +config/routes.rb+ as the *application's* route file. If the app and the Engine
# shared a root, the routes reloader would load that file under both routers and
# the Engine's +root+ route would be defined twice ("already in use: root").
require 'tmpdir'
RAKE_AUDIT_TEST_APP_ROOT = Dir.mktmpdir('rake_audit_test_app')

module RakeAuditTestApp
  # The dummy host application that mounts the Engine at +/rake_audit+.
  class Application < ::Rails::Application
    config.root = RAKE_AUDIT_TEST_APP_ROOT
    config.eager_load = false
    config.consider_all_requests_local = true
    config.active_support.deprecation = :stderr
    config.secret_key_base = 'rake-audit-test-secret-key-base'
    config.hosts.clear if config.respond_to?(:hosts)
    config.logger = Logger.new(IO::NULL)
    config.eager_load_paths = []

    # The app draws its routes from the support file below, not from a file on
    # disk; point the reloader at the (intentionally empty) app root.
    paths['config/routes.rb'] = []

    # Expose the Engine's app/views to the host so its controllers can render.
    initializer 'rake_audit.test.view_paths', after: :add_view_paths do
      engine_views = File.expand_path('../../app/views', __dir__)
      ActiveSupport.on_load(:action_controller) { append_view_path(engine_views) }
    end
  end
end

# Activate Kaminari's ActiveRecord page scope on the model (in a full Rails boot
# Kaminari's Railtie does this; here we trigger it explicitly so +.page+ works).
RakeAudit::TaskExecution.include(Kaminari::ActiveRecordModelExtension) unless
  RakeAudit::TaskExecution.respond_to?(:page)

RakeAuditTestApp::Application.initialize!

RakeAuditTestApp::Application.routes.draw do
  mount RakeAudit::Engine => '/rake_audit'
end

module WebUiAppHelpers
  # The Rack app under test: the booted dummy application.
  #
  # @return [RakeAuditTestApp::Application]
  def app
    RakeAuditTestApp::Application
  end

  # Convenience: create a persisted execution with sensible defaults that satisfy
  # the model's presence validations. Override any attribute via keyword args.
  #
  # @return [RakeAudit::TaskExecution]
  def create_execution(**attrs)
    defaults = {
      task_name: 'db:migrate',
      status: 'success',
      started_at: Time.now - 5,
      finished_at: Time.now,
      duration_ms: 5000,
      hostname: 'host-a',
      rails_env: 'test',
      pid: 1234,
      ruby_version: '3.1.6'
    }
    RakeAudit::TaskExecution.create!(defaults.merge(attrs))
  end
end
