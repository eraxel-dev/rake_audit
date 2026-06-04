# frozen_string_literal: true

# Demo Rake tasks for the rake_audit example app.
#
# Every task below is recorded automatically — rake_audit prepends a hook into
# Rake::Task#execute, so you do NOT add any auditing code yourself. Run a task,
# then inspect the result at http://localhost:3000/rake_audit or in the console:
#
#   RakeAudit::TaskExecution.order(started_at: :desc).first
#
namespace :demo do
  desc 'Trivial successful task — records a basic success row.'
  task hello: :environment do
    puts 'Hello from rake_audit! This run is recorded as status="success".'
  end

  desc 'Sleeps ~1.5s — demonstrates duration_ms capture.'
  task slow_report: :environment do
    puts 'Generating a slow report...'
    sleep 1.5
    puts 'Done. Check duration_ms on this execution — it should be ~1500ms.'
  end

  desc 'Accepts arguments — demonstrates the arguments column. ' \
       'Usage: bin/rails "demo:with_args[5,nightly]"'
  task :with_args, %i[count label] => :environment do |_task, args|
    count = Integer(args.fetch(:count, 1))
    label = args.fetch(:label, 'unlabeled')
    puts "Processing #{count} item(s) for label '#{label}'."
    count.times { |i| puts "  - item #{i + 1}" }
    puts 'The arguments hash is recorded on the audit row.'
  end

  desc 'Raises RuntimeError — demonstrates failure capture ' \
       '(status, error_class, error_message).'
  task flaky: :environment do
    puts 'Attempting a flaky operation...'
    raise 'Simulated failure: the flaky task always blows up.'
  end

  desc 'Seeds a realistic spread of execution records for the Web UI dashboard.'
  task seed_audit_data: :environment do
    require_relative '../../db/seeds_helper'
    created = RakeAudit::DemoSeeds.generate!
    puts "Seeded #{created} audit execution records."
    puts 'Open http://localhost:3000/rake_audit/dashboard to see the stats.'
  end
end
