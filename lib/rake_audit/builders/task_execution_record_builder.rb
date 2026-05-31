# frozen_string_literal: true

require 'socket'

require_relative '../task_execution_record'

module RakeAudit
  module Builders
    # Assembles a {RakeAudit::TaskExecutionRecord} from the raw inputs gathered
    # by {RakeAudit::ExecutionRecorder}: the task, its arguments, the timing
    # window, and any exception that was raised.
    #
    # Environment fields (hostname, pid, ruby version, rails env) are captured
    # here and are individually gated by the active {RakeAudit::Configuration}.
    module TaskExecutionRecordBuilder
      module_function

      # Build a record describing one execution.
      #
      # @param task [#name] the executed Rake task (only +#name+ is required).
      # @param args [Object, nil] arguments passed to the task.
      # @param started_at [Time] when execution began.
      # @param finished_at [Time] when execution finished (success or failure).
      # @param exception [Exception, nil] the raised exception, if the task failed.
      # @param config [RakeAudit::Configuration] configuration controlling capture.
      # @return [RakeAudit::TaskExecutionRecord]
      # rubocop:disable Metrics/ParameterLists, Metrics/CyclomaticComplexity
      def build(task:, args:, started_at:, finished_at:, exception:, config:)
        TaskExecutionRecord.new(
          task_name: task_name_for(task),
          arguments: normalize_arguments(args),
          started_at: started_at,
          finished_at: finished_at,
          duration_ms: duration_ms_for(started_at, finished_at),
          status: exception ? 'failure' : 'success',
          error_class: exception&.class&.name,
          error_message: exception&.message,
          hostname: config.capture_hostname ? Socket.gethostname : nil,
          pid: config.capture_pid ? Process.pid : nil,
          ruby_version: config.capture_ruby_version ? RUBY_VERSION : nil,
          rails_env: config.capture_rails_env ? rails_env : nil
        )
      end
      # rubocop:enable Metrics/ParameterLists, Metrics/CyclomaticComplexity

      # @api private
      def task_name_for(task)
        task.respond_to?(:name) ? task.name.to_s : task.to_s
      end

      # Coerce the task arguments into a plain Hash for stable serialization.
      #
      # Rake passes a +Rake::TaskArguments+ which responds to +#to_hash+; we also
      # accept a raw Hash and treat anything else (including +nil+) as empty.
      #
      # @api private
      # @return [Hash]
      def normalize_arguments(args)
        if args.respond_to?(:to_hash)
          args.to_hash
        elsif args.is_a?(Hash)
          args
        else
          {}
        end
      end

      # @api private
      # @return [Integer] elapsed wall-clock time in whole milliseconds.
      def duration_ms_for(started_at, finished_at)
        ((finished_at - started_at) * 1000).round
      end

      # @api private
      # @return [String, nil] the current Rails environment, when available.
      def rails_env
        return nil unless defined?(Rails) && Rails.respond_to?(:env)

        Rails.env.to_s
      end
    end
  end
end
