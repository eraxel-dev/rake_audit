# frozen_string_literal: true

# Populate the audit table with a realistic spread of executions so the Web UI
# dashboard shows non-trivial stats immediately after `bin/rails db:setup`.
#
# The generation logic lives in db/seeds_helper.rb so it is shared with the
# `demo:seed_audit_data` Rake task.
require_relative 'seeds_helper'

created = RakeAudit::DemoSeeds.generate!
puts "Seeded #{created} rake_audit execution records."
puts 'Visit http://localhost:3000/rake_audit/dashboard to see them.'
