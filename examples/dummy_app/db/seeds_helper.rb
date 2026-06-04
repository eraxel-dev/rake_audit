# frozen_string_literal: true

module RakeAudit
  # Generates a realistic spread of TaskExecution rows so the Web UI dashboard
  # shows non-trivial stats on first visit. Shared by db/seeds.rb and the
  # demo:seed_audit_data Rake task so there is a single source of truth.
  module DemoSeeds
    TASK_NAMES = %w[
      db:migrate db:seed reports:nightly mailers:digest cache:warm
      demo:hello demo:slow_report
    ].freeze

    HOSTS = %w[web-01 web-02 worker-01].freeze

    # Insert a spread of success and failure executions across the last week.
    #
    # @return [Integer] number of records created.
    def self.generate!
      base = Time.now.utc
      created = 0

      60.times do |i|
        created += 1 if insert_record(base, i)
      end

      created
    end

    # @return [Boolean] whether a row was created.
    def self.insert_record(base, index)
      failure = (index % 7).zero?
      started = base - (index * 1800) # every 30 minutes back in time
      duration = failure ? rand(20..300) : rand(50..2500)

      RakeAudit::TaskExecution.create!(
        record_attributes(index, failure, started, duration)
      )
      true
    end

    # @return [Hash]
    def self.record_attributes(index, failure, started, duration)
      {
        task_name: TASK_NAMES[index % TASK_NAMES.length],
        arguments: index.even? ? { 'count' => index, 'label' => 'seed' } : nil,
        started_at: started,
        finished_at: started + (duration / 1000.0),
        duration_ms: duration,
        status: failure ? 'failure' : 'success',
        error_class: failure ? 'RuntimeError' : nil,
        error_message: failure ? 'Simulated failure for dashboard demo data' : nil,
        hostname: HOSTS[index % HOSTS.length],
        pid: 1000 + index,
        ruby_version: RUBY_VERSION,
        rails_env: 'development'
      }
    end

    private_class_method :insert_record, :record_attributes
  end
end
