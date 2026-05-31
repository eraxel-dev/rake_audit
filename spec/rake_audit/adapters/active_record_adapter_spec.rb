# frozen_string_literal: true

require 'rake_audit/adapters/active_record_adapter'

RSpec.describe RakeAudit::Adapters::ActiveRecordAdapter do
  subject(:adapter) { described_class.new }

  let(:record_hash) do
    { task_name: 'db:migrate', status: 'success', arguments: {} }
  end
  let(:record) { instance_double(RakeAudit::TaskExecutionRecord, to_h: record_hash) }

  before do
    stub_const('RakeAudit::TaskExecution', Class.new { def self.create!(_attrs); end })
  end

  describe '#save' do
    it 'inherits from Base' do
      expect(described_class.ancestors).to include(RakeAudit::Adapters::Base)
    end

    it 'calls TaskExecution.create! with record.to_h' do
      expect(RakeAudit::TaskExecution).to receive(:create!).with(record_hash)
      adapter.save(record)
    end
  end
end
