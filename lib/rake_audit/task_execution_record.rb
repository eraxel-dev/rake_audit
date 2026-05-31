# frozen_string_literal: true

module RakeAudit
  # Immutable data transfer object describing a single Rake task execution.
  #
  # This Struct is the serialization boundary used by every storage adapter:
  # adapters must rely on {#to_h} and never reach into internal state directly.
  TaskExecutionRecord = Struct.new(
    :task_name,
    :arguments,
    :started_at,
    :finished_at,
    :duration_ms,
    :status,
    :error_class,
    :error_message,
    :hostname,
    :pid,
    :ruby_version,
    :rails_env,
    keyword_init: true
  ) do
    # The canonical, adapter-facing serialization of this record.
    #
    # Always returns a plain Hash containing all 12 fields, regardless of how
    # the record was constructed. Adapters depend on this exact contract.
    #
    # @return [Hash{Symbol=>Object}]
    def to_h
      {
        task_name: task_name,
        arguments: arguments,
        started_at: started_at,
        finished_at: finished_at,
        duration_ms: duration_ms,
        status: status,
        error_class: error_class,
        error_message: error_message,
        hostname: hostname,
        pid: pid,
        ruby_version: ruby_version,
        rails_env: rails_env
      }
    end
  end
end
