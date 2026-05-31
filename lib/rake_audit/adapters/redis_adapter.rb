# frozen_string_literal: true

require_relative 'base'
require 'json'

module RakeAudit
  module Adapters
    # Persists TaskExecutionRecord instances via Redis LPUSH.
    class RedisAdapter < Base
      # @param client [Redis] a connected Redis client instance.
      def initialize(client:)
        super()
        @client = client
      end

      # Push the serialized record onto the executions list.
      #
      # @param record [TaskExecutionRecord] the record to persist.
      def save(record)
        @client.lpush('rake_audit:executions', record.to_h.to_json)
      end
    end
  end
end
