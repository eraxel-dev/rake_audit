# frozen_string_literal: true

require_relative 'builders/task_execution_record_builder'

module RakeAudit
  # Wraps a single Rake task execution to capture timing, success/failure, and
  # any raised exception, then persists a {TaskExecutionRecord} via the
  # configured adapter.
  #
  # Design invariants:
  # - The original task exception always propagates unchanged (re-raised).
  # - Persistence happens in an +ensure+ block so it runs on both success and
  #   failure paths.
  # - Adapter errors are logged and swallowed; they never affect the task result.
  # - When no adapter is configured, saving is skipped entirely.
  class ExecutionRecorder
    # @param task [#name] the Rake task being executed.
    # @param args [Object, nil] arguments passed to the task.
    def initialize(task:, args: nil)
      @task = task
      @args = args
    end

    # Execute the given block, capturing timing and outcome.
    #
    # @yield runs the wrapped task body (typically +super+ from the patch).
    # @return [Object] the block's return value on success.
    # @raise [Exception] re-raises whatever the block raised, unchanged.
    def record
      started_at = now
      exception = nil
      begin
        yield
      rescue Exception => e # rubocop:disable Lint/RescueException
        exception = e
        raise
      ensure
        finished_at = now
        save_record(started_at: started_at, finished_at: finished_at, exception: exception)
      end
    end

    private

    attr_reader :task, :args

    # Build and persist the record. Never raises: adapter failures are logged.
    def save_record(started_at:, finished_at:, exception:)
      config = RakeAudit.config
      adapter = config.adapter
      return if adapter.nil?

      record = Builders::TaskExecutionRecordBuilder.build(
        task: task,
        args: args,
        started_at: started_at,
        finished_at: finished_at,
        exception: exception,
        config: config
      )
      adapter.save(record)
    rescue StandardError => e
      log_save_failure(config, e)
    end

    def log_save_failure(config, error)
      logger = config&.logger
      return unless logger.respond_to?(:error)

      logger.error("[RakeAudit] Save failed: #{error.class}: #{error.message}")
    end

    # @return [Time] monotonic-friendly current wall-clock time.
    def now
      Time.now
    end
  end
end
