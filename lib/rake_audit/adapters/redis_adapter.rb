# frozen_string_literal: true

require_relative 'base'
require_relative 'execution_record'
require_relative '../record_not_found'
require 'json'
require 'securerandom'

module RakeAudit
  module Adapters
    # Persists and queries TaskExecutionRecord instances via Redis.
    #
    # Each record is serialized as JSON (with a generated UUID +id+ field) and
    # prepended to the +rake_audit:executions+ list key via +LPUSH+. Query
    # methods read the full list and filter/sort/paginate in Ruby, making this
    # adapter suitable for low-to-moderate write volumes where a full DB is
    # unavailable but basic Web UI introspection is still desired.
    class RedisAdapter < Base # rubocop:disable Metrics/ClassLength
      # @param client [Redis] a connected Redis client instance.
      def initialize(client:)
        super()
        @client = client
      end

      # Push the serialized record onto the executions list.
      # A UUID +id+ is generated and embedded so the Web UI can link to details.
      #
      # @param record [TaskExecutionRecord]
      def save(record)
        data = record.to_h.merge(id: SecureRandom.uuid)
        @client.lpush('rake_audit:executions', data.to_json)
      end

      # @param filters [Hash] pre-validated non-blank filter values.
      # @param page [Integer, String, nil]
      # @param per_page [Integer]
      # @return [Kaminari::PaginatableArray]
      def query(filters: {}, page: nil, per_page: 25)
        require 'kaminari'
        records = filtered_and_sorted(filters)
        total   = records.size
        current = [page.to_i, 1].max
        paged   = records.slice((current - 1) * per_page, per_page) || []

        Kaminari
          .paginate_array(paged.map { |r| to_execution_record(r) }, total_count: total)
          .page(current)
          .per(per_page)
      end

      # @param id [String] UUID stored at write time.
      # @return [RakeAudit::Adapters::ExecutionRecord]
      # @raise [RakeAudit::RecordNotFound]
      def find(id)
        raw = all_records.find { |r| r[:id].to_s == id.to_s }
        raise RakeAudit::RecordNotFound, "Couldn't find execution with id=#{id}" unless raw

        to_execution_record(raw)
      end

      # @return [Integer]
      def count
        all_records.size
      end

      # @param status [String]
      # @return [Integer]
      def count_by_status(status)
        all_records.count { |r| r[:status].to_s == status }
      end

      # @return [Float, nil]
      def average_duration_ms
        records = all_records
        return nil if records.empty?

        records.sum { |r| r[:duration_ms].to_f } / records.size
      end

      # @param limit [Integer]
      # @return [Array<Array(String, Integer)>]
      def top_failed_tasks(limit: 10)
        top_failed_from(all_records.select { |r| r[:status].to_s == 'failure' }, limit: limit)
      end

      # Single-pass override: reads the full Redis list once and derives all five
      # dashboard metrics in memory, replacing the default five-separate-LRANGE
      # implementation inherited from Base.
      #
      # @return [Hash]
      def stats
        records      = all_records
        total        = records.size
        failure_recs = records.select { |r| r[:status].to_s == 'failure' }

        {
          total: total,
          success_count: records.count { |r| r[:status].to_s == 'success' },
          failure_count: failure_recs.size,
          average_duration_ms: avg_duration(records, total),
          top_failed_tasks: top_failed_from(failure_recs)
        }
      end

      private

      def all_records
        @client
          .lrange('rake_audit:executions', 0, -1)
          .map { |json| JSON.parse(json, symbolize_names: true) }
      end

      def avg_duration(records, total)
        total.zero? ? nil : records.sum { |r| r[:duration_ms].to_f } / total
      end

      def top_failed_from(failure_records, limit: 10)
        failure_records
          .group_by { |r| r[:task_name].to_s }
          .transform_values(&:size)
          .sort_by { |_, c| -c }
          .first(limit)
          .map { |name, c| [name, c] }
      end

      def filtered_and_sorted(filters)
        apply_date_range(apply_exact_filters(all_records, filters), filters)
          .sort_by { |r| parse_time(r[:started_at]).to_i }
          .reverse
      end

      def apply_exact_filters(records, filters)
        %i[task_name status hostname rails_env].reduce(records) do |recs, col|
          next recs unless filters.key?(col)

          recs.select { |r| r[col].to_s == filters[col].to_s }
        end
      end

      def apply_date_range(records, filters)
        records = records.select { |r| parse_time(r[:started_at]) >= parse_time(filters[:from]) } if filters.key?(:from)
        records = records.select { |r| parse_time(r[:started_at]) <= parse_time(filters[:to]) }   if filters.key?(:to)
        records
      end

      def parse_time(value)
        return Time.at(0) if value.nil?
        return value if value.is_a?(Time)

        Time.parse(value.to_s)
      rescue ArgumentError
        Time.at(0)
      end

      def to_execution_record(raw)
        RakeAudit::Adapters::ExecutionRecord.new(
          id: raw[:id]&.to_s,
          task_name: raw[:task_name],
          arguments: raw[:arguments],
          started_at: raw[:started_at],
          finished_at: raw[:finished_at],
          duration_ms: raw[:duration_ms],
          status: raw[:status],
          error_class: raw[:error_class],
          error_message: raw[:error_message],
          hostname: raw[:hostname],
          pid: raw[:pid],
          ruby_version: raw[:ruby_version],
          rails_env: raw[:rails_env]
        )
      end
    end
  end
end
