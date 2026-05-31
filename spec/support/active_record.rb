# frozen_string_literal: true

# Boot a minimal ActiveRecord environment for the model/migration specs.
#
# +logger+ must be required before +active_record+ on Ruby 3.1 + ActiveSupport
# 7.0, otherwise ActiveSupport's LoggerThreadSafeLevel references the +Logger+
# constant before it is defined and load fails.
require 'logger'
require 'active_record'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

# Load the gem's model once the connection exists. The +app/models+ path is not
# on the default load path outside Rails, so require it explicitly.
require_relative '../../app/models/rake_audit/task_execution'

# Recreate the schema before each example group that opts in via
# +:active_record+ metadata, keeping examples isolated.
module ActiveRecordTestSupport
  module_function

  # Run the gem's real migration against the in-memory database.
  #
  # @return [void]
  def load_schema!
    migration_path = File.expand_path(
      '../../db/migrate/20260531120000_create_rake_task_executions.rb', __dir__
    )
    require migration_path
    silence_stream { CreateRakeTaskExecutions.new.change }
  end

  # Drop the table so the next migration run starts clean.
  #
  # @return [void]
  def drop_schema!
    conn = ActiveRecord::Base.connection
    conn.drop_table(:rake_task_executions) if conn.table_exists?(:rake_task_executions)
  end

  # Suppress ActiveRecord migration chatter on stdout/stderr.
  def silence_stream
    ActiveRecord::Migration.verbose = false
    yield
  end
end

RSpec.configure do |config|
  config.before(:each, :active_record) do
    ActiveRecordTestSupport.drop_schema!
    ActiveRecordTestSupport.load_schema!
  end

  config.after(:each, :active_record) do
    ActiveRecordTestSupport.drop_schema!
  end
end
