# frozen_string_literal: true

module RakeAudit
  module Adapters
    # Abstract storage adapter defining the full persistence and query contract.
    #
    # Every concrete adapter must implement +#save+. Adapters that back the Web
    # UI must also implement the six query methods below; the default
    # implementations raise +NotImplementedError+ so omissions surface loudly.
    class Base
      # Persist a TaskExecutionRecord.
      #
      # @param record [TaskExecutionRecord] the record to save.
      # @raise [NotImplementedError] when not overridden.
      def save(record)
        raise NotImplementedError, "#{self.class}#save is not implemented"
      end

      # Return a kaminari-paginated, filtered, newest-first collection.
      #
      # @param filters [Hash] any subset of: +:task_name+, +:status+,
      #   +:hostname+, +:rails_env+, +:from+, +:to+ (all pre-validated,
      #   non-blank values only — blank keys are never present).
      # @param page [Integer, String, nil] 1-based page number.
      # @param per_page [Integer] records per page.
      # @raise [NotImplementedError] when not overridden.
      def query(filters: {}, page: nil, per_page: 25)
        raise NotImplementedError, "#{self.class}#query is not implemented"
      end

      # Return a single execution record by ID.
      #
      # @param id [String, Integer] adapter-specific identifier.
      # @raise [RakeAudit::RecordNotFound] when no record matches.
      # @raise [NotImplementedError] when not overridden.
      def find(id)
        raise NotImplementedError, "#{self.class}#find is not implemented"
      end

      # Total number of stored executions.
      #
      # @return [Integer]
      # @raise [NotImplementedError] when not overridden.
      def count
        raise NotImplementedError, "#{self.class}#count is not implemented"
      end

      # Number of executions whose +status+ equals +status+.
      #
      # @param status [String] e.g. <tt>"success"</tt> or <tt>"failure"</tt>.
      # @return [Integer]
      # @raise [NotImplementedError] when not overridden.
      def count_by_status(status)
        raise NotImplementedError, "#{self.class}#count_by_status is not implemented"
      end

      # Mean +duration_ms+ across all stored executions, or +nil+ when empty.
      #
      # @return [Float, nil]
      # @raise [NotImplementedError] when not overridden.
      def average_duration_ms
        raise NotImplementedError, "#{self.class}#average_duration_ms is not implemented"
      end

      # The +limit+ task names with the most failures, ordered descending.
      #
      # @param limit [Integer]
      # @return [Array<Array(String, Integer)>] e.g. +[["db:migrate", 5], ...]+
      # @raise [NotImplementedError] when not overridden.
      def top_failed_tasks(limit: 10)
        raise NotImplementedError, "#{self.class}#top_failed_tasks is not implemented"
      end

      # All five dashboard metrics in a single call.
      #
      # The default implementation delegates to the five individual methods, which
      # is efficient for SQL-backed adapters (five fast queries). Adapters whose
      # individual methods are expensive (e.g. Redis, which reads the full list
      # per call) should override this to compute everything in one pass.
      #
      # @return [Hash] with keys +:total+, +:success_count+, +:failure_count+,
      #   +:average_duration_ms+, +:top_failed_tasks+.
      def stats
        {
          total: count,
          success_count: count_by_status('success'),
          failure_count: count_by_status('failure'),
          average_duration_ms: average_duration_ms,
          top_failed_tasks: top_failed_tasks
        }
      end
    end
  end
end
