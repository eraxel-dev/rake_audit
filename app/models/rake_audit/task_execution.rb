# frozen_string_literal: true

module RakeAudit
  # ActiveRecord model backing the +rake_task_executions+ table.
  #
  # This is the persistence target of {RakeAudit::Adapters::ActiveRecordAdapter},
  # which calls +TaskExecution.create!(record.to_h)+ with the twelve fields a
  # {RakeAudit::TaskExecutionRecord} serializes. The four columns that are
  # always populated for a completed execution carry presence validations so a
  # malformed record fails loudly rather than persisting a partial row.
  #
  # When the host application defines an +ApplicationRecord+ the model inherits
  # from it (picking up the app's connection and conventions); otherwise it
  # falls back to +ActiveRecord::Base+ so the gem also works in a plain
  # ActiveRecord setup without Rails.
  class TaskExecution < (defined?(ApplicationRecord) ? ApplicationRecord : ActiveRecord::Base)
    self.table_name = 'rake_task_executions'

    # Treat +arguments+ as JSON on every backend so a Hash round-trips to a Hash.
    # On PostgreSQL/MySQL the column is natively json(b); on SQLite it is +text+,
    # where without an explicit JSON type a Hash would be stored via Ruby's
    # +to_s+ and read back as a String. +ActiveRecord::Type::Json+ casts Hash to
    # JSON on write and back on read for both column kinds, needs no database
    # connection at load time, and never raises — unlike +serialize+, which
    # rejects a natively JSON-typed column.
    attribute :arguments, ActiveRecord::Type::Json.new

    validates :task_name, presence: true
    validates :status, presence: true
    validates :started_at, presence: true
    validates :finished_at, presence: true
  end
end
