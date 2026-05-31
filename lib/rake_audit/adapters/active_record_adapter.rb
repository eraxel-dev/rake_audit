# frozen_string_literal: true

require_relative 'base'

module RakeAudit
  module Adapters
    # Persists TaskExecutionRecord instances via ActiveRecord.
    class ActiveRecordAdapter < Base
      # Create a TaskExecution row from the given record.
      #
      # @param record [TaskExecutionRecord] the record to persist.
      def save(record)
        RakeAudit::TaskExecution.create!(record.to_h)
      end
    end
  end
end
