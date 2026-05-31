# frozen_string_literal: true

require 'spec_helper'
require 'rake_audit/adapters/active_record_adapter'

RSpec.describe RakeAudit::Adapters::ActiveRecordAdapter, :active_record do
  subject(:adapter) { described_class.new }

  let(:record) do
    RakeAudit::TaskExecutionRecord.new(
      task_name: 'reports:generate',
      arguments: { 'month' => '2026-05' },
      started_at: Time.now,
      finished_at: Time.now + 1,
      duration_ms: 1000,
      status: 'success',
      error_class: nil,
      error_message: nil,
      hostname: 'worker-1',
      pid: Process.pid,
      ruby_version: RUBY_VERSION,
      rails_env: 'test'
    )
  end

  it 'persists a TaskExecutionRecord through the model' do
    adapter.save(record)

    row = RakeAudit::TaskExecution.last
    expect(row.task_name).to eq('reports:generate')
    expect(row.status).to eq('success')
    expect(row.duration_ms).to eq(1000)
    expect(row.hostname).to eq('worker-1')
  end

  it 'raises when the record is missing a required field' do
    invalid = record.to_h.merge(task_name: nil)
    bad_record = RakeAudit::TaskExecutionRecord.new(**invalid)

    expect { adapter.save(bad_record) }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
