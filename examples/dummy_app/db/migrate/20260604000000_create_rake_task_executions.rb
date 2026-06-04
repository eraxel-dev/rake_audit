# frozen_string_literal: true

# Creates the +rake_task_executions+ table that backs RakeAudit::TaskExecution.
#
# This file is the output of `bin/rails generate rake_audit:install` (the
# install generator copies the gem's template and stamps the current schema
# version). On SQLite the +arguments+ column resolves to +text+; the model
# casts it to/from JSON via ActiveRecord::Type::Json so a Hash round-trips.
class CreateRakeTaskExecutions < ActiveRecord::Migration[7.0]
  def change
    create_table :rake_task_executions do |t|
      t.string :task_name, null: false, limit: 255
      t.column :arguments, arguments_column_type, null: true
      t.datetime :started_at, null: false
      t.datetime :finished_at, null: false
      t.bigint :duration_ms, null: true
      t.string :status, null: false, limit: 20
      t.string :error_class, null: true, limit: 255
      t.text :error_message, null: true
      t.string :hostname, null: true, limit: 255
      t.integer :pid, null: true
      t.string :ruby_version, null: true, limit: 50
      t.string :rails_env, null: true, limit: 50

      t.timestamps
    end

    add_audit_indexes
  end

  private

  # Add the four single-column and two composite indexes.
  def add_audit_indexes
    add_index :rake_task_executions, :task_name
    add_index :rake_task_executions, :status
    add_index :rake_task_executions, :started_at
    add_index :rake_task_executions, :hostname
    add_index :rake_task_executions, %i[task_name started_at]
    add_index :rake_task_executions, %i[status started_at]
  end

  # Pick a JSON-capable column type the current database supports, falling back
  # to +text+ (used by SQLite) so the migration is portable across backends.
  def arguments_column_type
    adapter = connection.adapter_name.downcase
    if adapter.include?('postgresql')
      :jsonb
    elsif adapter.include?('mysql')
      :json
    else
      :text
    end
  end
end
