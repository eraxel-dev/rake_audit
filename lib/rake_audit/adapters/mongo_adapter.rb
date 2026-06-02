# frozen_string_literal: true

require_relative 'base'
require_relative 'execution_record'
require_relative '../record_not_found'

module RakeAudit
  module Adapters
    # Persists and queries TaskExecutionRecord instances via MongoDB.
    #
    # Uses the MongoDB Ruby driver directly. Documents are stored in the
    # +rake_task_executions+ collection and Mongo's native +_id+ (ObjectId) is
    # used as the record identifier for Web UI links.
    class MongoAdapter < Base
      # @param client [Mongo::Client] a connected MongoDB client instance.
      def initialize(client:)
        super()
        @client = client
      end

      # Insert the record into the executions collection.
      #
      # @param record [TaskExecutionRecord]
      def save(record)
        collection.insert_one(record.to_h)
      end

      # @param filters [Hash] pre-validated non-blank filter values.
      # @param page [Integer, String, nil]
      # @param per_page [Integer]
      # @return [Kaminari::PaginatableArray]
      def query(filters: {}, page: nil, per_page: 25)
        require 'kaminari'
        filter      = build_filter(filters)
        total       = collection.count_documents(filter)
        current     = [page.to_i, 1].max
        cursor      = collection.find(filter)
                                .sort(started_at: -1)
                                .skip((current - 1) * per_page)
                                .limit(per_page)

        records = cursor.map { |doc| to_execution_record(doc) }
        Kaminari
          .paginate_array(records, total_count: total)
          .page(current)
          .per(per_page)
      end

      # @param id [String] string representation of a Mongo ObjectId.
      # @return [RakeAudit::Adapters::ExecutionRecord]
      # @raise [RakeAudit::RecordNotFound]
      def find(id)
        # Skip the require when BSON is already defined (e.g. stubbed in tests).
        require 'bson' unless defined?(BSON)
        object_id = BSON::ObjectId.from_string(id.to_s)
        doc = collection.find(_id: object_id).first
        raise RakeAudit::RecordNotFound, "Couldn't find execution with id=#{id}" unless doc

        to_execution_record(doc)
      rescue ArgumentError
        # BSON::ObjectId::Invalid inherits from ArgumentError — invalid id string.
        raise RakeAudit::RecordNotFound, "Couldn't find execution with id=#{id}"
      end

      # @return [Integer]
      def count
        collection.count_documents({})
      end

      # @param status [String]
      # @return [Integer]
      def count_by_status(status)
        collection.count_documents('status' => status)
      end

      # @return [Float, nil]
      def average_duration_ms
        result = collection.aggregate([
                                        { '$group' => { '_id' => nil, 'avg' => { '$avg' => '$duration_ms' } } }
                                      ]).first
        result ? result['avg'] : nil
      end

      # @param limit [Integer]
      # @return [Array<Array(String, Integer)>]
      def top_failed_tasks(limit: 10)
        collection.aggregate([
                               { '$match' => { 'status' => 'failure' } },
                               { '$group'  => { '_id' => '$task_name', 'count' => { '$sum' => 1 } } },
                               { '$sort'   => { 'count' => -1 } },
                               { '$limit'  => limit }
                             ]).map { |doc| [doc['_id'], doc['count']] }
      end

      private

      def collection
        @client['rake_task_executions']
      end

      def build_filter(filters)
        filter = {}

        %i[task_name status hostname rails_env].each do |col|
          filter[col.to_s] = filters[col] if filters.key?(col)
        end

        if filters.key?(:from) || filters.key?(:to)
          range = {}
          range['$gte'] = filters[:from].to_s if filters.key?(:from)
          range['$lte'] = filters[:to].to_s   if filters.key?(:to)
          filter['started_at'] = range
        end

        filter
      end

      def to_execution_record(doc)
        RakeAudit::Adapters::ExecutionRecord.new(
          id: doc['_id']&.to_s,
          task_name: doc['task_name'],
          arguments: doc['arguments'],
          started_at: doc['started_at'],
          finished_at: doc['finished_at'],
          duration_ms: doc['duration_ms'],
          status: doc['status'],
          error_class: doc['error_class'],
          error_message: doc['error_message'],
          hostname: doc['hostname'],
          pid: doc['pid'],
          ruby_version: doc['ruby_version'],
          rails_env: doc['rails_env']
        )
      end
    end
  end
end
