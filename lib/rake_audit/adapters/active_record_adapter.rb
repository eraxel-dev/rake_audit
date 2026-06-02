# frozen_string_literal: true

require_relative 'base'
require_relative '../record_not_found'

module RakeAudit
  module Adapters
    # Persists and queries TaskExecutionRecord instances via ActiveRecord.
    class ActiveRecordAdapter < Base
      EXACT_FILTERS = %i[task_name status hostname rails_env].freeze
      private_constant :EXACT_FILTERS

      # Create a TaskExecution row from the given record.
      #
      # @param record [TaskExecutionRecord]
      def save(record)
        RakeAudit::TaskExecution.create!(record.to_h)
      end

      # @param filters [Hash] pre-validated non-blank filter values.
      # @param page [Integer, String, nil]
      # @param per_page [Integer]
      # @return [ActiveRecord::Relation] kaminari-paginated relation.
      def query(filters: {}, page: nil, per_page: 25)
        scope = RakeAudit::TaskExecution.order(started_at: :desc)

        EXACT_FILTERS.each do |col|
          scope = scope.where(col => filters[col]) if filters.key?(col)
        end
        scope = scope.where(started_at: filters[:from]..) if filters.key?(:from)
        scope = scope.where(started_at: ..filters[:to])   if filters.key?(:to)

        scope.page(page).per(per_page)
      end

      # @param id [Integer, String]
      # @return [RakeAudit::TaskExecution]
      # @raise [RakeAudit::RecordNotFound]
      def find(id)
        RakeAudit::TaskExecution.find(id)
      rescue ActiveRecord::RecordNotFound
        raise RakeAudit::RecordNotFound, "Couldn't find execution with id=#{id}"
      end

      # @return [Integer]
      def count
        RakeAudit::TaskExecution.count
      end

      # @param status [String]
      # @return [Integer]
      def count_by_status(status)
        RakeAudit::TaskExecution.where(status: status).count
      end

      # @return [Float, nil]
      def average_duration_ms
        RakeAudit::TaskExecution.average(:duration_ms)
      end

      # @param limit [Integer]
      # @return [Array<Array(String, Integer)>]
      def top_failed_tasks(limit: 10)
        RakeAudit::TaskExecution
          .where(status: 'failure')
          .group(:task_name)
          .count
          .sort_by { |_, c| -c }
          .first(limit)
      end
    end
  end
end
