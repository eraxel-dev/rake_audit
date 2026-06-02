# frozen_string_literal: true

module RakeAudit
  module Adapters
    # Read-side value object returned by non-ActiveRecord adapters.
    #
    # Carries every field the Web UI views access plus an +id+ and +to_param+
    # so Rails route helpers (+execution_path(record)+) work without AR.
    ExecutionRecord = Struct.new(
      :id, :task_name, :arguments, :started_at, :finished_at,
      :duration_ms, :status, :error_class, :error_message,
      :hostname, :pid, :ruby_version, :rails_env,
      keyword_init: true
    ) do
      def to_param
        id.to_s
      end
    end
  end
end
