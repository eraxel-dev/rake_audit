# frozen_string_literal: true

module RakeAudit
  module Adapters
    # Abstract storage adapter defining the persistence contract.
    class Base
      # Persist a TaskExecutionRecord.
      #
      # @param record [TaskExecutionRecord] the record to save.
      # @raise [NotImplementedError] when not overridden by a subclass.
      def save(record)
        raise NotImplementedError, "#{self.class}#save is not implemented"
      end
    end
  end
end
