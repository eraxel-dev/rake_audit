# frozen_string_literal: true

require_relative 'base'

module RakeAudit
  module Adapters
    # Persists TaskExecutionRecord instances via MongoDB insert_one.
    class MongoAdapter < Base
      # @param client [Mongo::Client] a connected MongoDB client instance.
      def initialize(client:)
        super()
        @client = client
      end

      # Insert the record into the executions collection.
      #
      # @param record [TaskExecutionRecord] the record to persist.
      def save(record)
        collection.insert_one(record.to_h)
      end

      private

      def collection
        @client['rake_task_executions']
      end
    end
  end
end
