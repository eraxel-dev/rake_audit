# frozen_string_literal: true

require_relative 'execution_recorder'

module RakeAudit
  # Module prepended into +Rake::Task+ so that every executed task is routed
  # through an {ExecutionRecorder}. Prepending lets us wrap +#execute+ while
  # still delegating to the original implementation via +super+.
  module TaskPatch
    # Intercept Rake task execution.
    #
    # @param args [Object, nil] arguments Rake passes to the task.
    # @return [Object] the original +#execute+ return value.
    # @raise [Exception] propagates whatever the underlying task raised.
    def execute(args = nil)
      ExecutionRecorder.new(task: self, args: args).record { super }
    end
  end
end
