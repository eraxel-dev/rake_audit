# frozen_string_literal: true

require 'rake_audit/adapters/redis_adapter'

RSpec.describe RakeAudit::Adapters::RedisAdapter do
  let(:redis_client) { instance_double('Redis') }
  subject(:adapter) { described_class.new(client: redis_client) }

  let(:record_hash) { { task_name: 'cache:clear', status: 'success' } }
  let(:record) { instance_double(RakeAudit::TaskExecutionRecord, to_h: record_hash) }

  describe '#save' do
    it 'inherits from Base' do
      expect(described_class.ancestors).to include(RakeAudit::Adapters::Base)
    end

    it 'LPUSHes JSON to rake_audit:executions' do
      expect(redis_client).to receive(:lpush).with('rake_audit:executions', record_hash.to_json)
      adapter.save(record)
    end
  end
end
