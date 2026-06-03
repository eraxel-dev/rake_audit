# frozen_string_literal: true

# Shared boot for the system specs. These drive the full Web UI (routes,
# controllers, views, pagination) through the Engine mounted in a minimal Rails
# app, exercised over Rack via rack-test.
#
# The gem deliberately avoids a hard Rails dependency, so the Action Pack / View
# and rack-test requirements are loaded lazily here. When they are unavailable
# the dependent example groups are skipped via the SYSTEM_SPECS_AVAILABLE flag,
# keeping the rest of the suite runnable.
require 'spec_helper'

begin
  require 'rack/test'
  require_relative '../support/web_ui_app'
  require 'rake_audit/adapters/active_record_adapter'
  SYSTEM_SPECS_AVAILABLE = true
rescue LoadError => e
  warn "System specs skipped: #{e.message}"
  SYSTEM_SPECS_AVAILABLE = false
end
