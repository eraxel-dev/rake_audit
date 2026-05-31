# frozen_string_literal: true

require 'rake_audit/adapters/mongo_adapter'

RSpec.describe RakeAudit::Adapters::MongoAdapter do
  let(:collection) { instance_double('Mongo::Collection') }
  let(:mongo_client) { instance_double('Mongo::Client') }
  subject(:adapter) { described_class.new(client: mongo_client) }

  let(:record_hash) { { task_name: 'reports:build', status: 'success' } }
  let(:record) { instance_double(RakeAudit::TaskExecutionRecord, to_h: record_hash) }

  before do
    allow(mongo_client).to receive(:[]).with('rake_task_executions').and_return(collection)
  end

  describe '#save' do
    it 'inherits from Base' do
      expect(described_class.ancestors).to include(RakeAudit::Adapters::Base)
    end

    it 'calls insert_one on the rake_task_executions collection' do
      expect(mongo_client).to receive(:[]).with('rake_task_executions').and_return(collection)
      expect(collection).to receive(:insert_one).with(record_hash)
      adapter.save(record)
    end
  end
end
