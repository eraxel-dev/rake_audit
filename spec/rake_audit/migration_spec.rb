# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CreateRakeTaskExecutions migration', :active_record do
  let(:connection) { ActiveRecord::Base.connection }
  let(:columns) { connection.columns(:rake_task_executions).index_by(&:name) }

  it 'creates the rake_task_executions table' do
    expect(connection.table_exists?(:rake_task_executions)).to be(true)
  end

  describe 'columns' do
    it 'defines every specified column' do
      expected = %w[
        id task_name arguments started_at finished_at duration_ms status
        error_class error_message hostname pid ruby_version rails_env
        created_at updated_at
      ]
      expect(columns.keys).to include(*expected)
    end

    it 'marks task_name, started_at, finished_at, and status as NOT NULL' do
      %w[task_name started_at finished_at status].each do |name|
        expect(columns.fetch(name).null).to be(false), "#{name} should be NOT NULL"
      end
    end

    it 'leaves the optional metadata columns nullable' do
      %w[arguments duration_ms error_class error_message hostname pid
         ruby_version rails_env].each do |name|
        expect(columns.fetch(name).null).to be(true), "#{name} should be nullable"
      end
    end

    it 'uses a bigint for duration_ms' do
      expect(columns.fetch('duration_ms').sql_type).to match(/bigint|integer/i)
    end
  end

  describe 'indexes' do
    let(:index_columns) do
      connection.indexes(:rake_task_executions).map(&:columns)
    end

    it 'creates all six indexes (four single, two composite)' do
      expect(index_columns).to include(['task_name'])
      expect(index_columns).to include(['status'])
      expect(index_columns).to include(['started_at'])
      expect(index_columns).to include(['hostname'])
      expect(index_columns).to include(%w[task_name started_at])
      expect(index_columns).to include(%w[status started_at])
    end

    it 'creates exactly six indexes' do
      expect(index_columns.size).to eq(6)
    end
  end
end
