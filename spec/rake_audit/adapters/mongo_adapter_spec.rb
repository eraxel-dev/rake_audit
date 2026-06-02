# frozen_string_literal: true

require 'rake_audit/adapters/mongo_adapter'

RSpec.describe RakeAudit::Adapters::MongoAdapter do
  let(:collection)   { instance_double('Mongo::Collection') }
  let(:mongo_client) { instance_double('Mongo::Client') }
  subject(:adapter)  { described_class.new(client: mongo_client) }

  let(:record_hash) { { task_name: 'reports:build', status: 'success' } }
  let(:record) { instance_double(RakeAudit::TaskExecutionRecord, to_h: record_hash) }

  before do
    allow(mongo_client).to receive(:[]).with('rake_task_executions').and_return(collection)
  end

  it 'inherits from Base' do
    expect(described_class.ancestors).to include(RakeAudit::Adapters::Base)
  end

  describe '#save' do
    it 'calls insert_one on the rake_task_executions collection' do
      expect(collection).to receive(:insert_one).with(record_hash)
      adapter.save(record)
    end
  end

  # --- query helpers -------------------------------------------------------

  let(:object_id_a) { double('BSON::ObjectId', to_s: 'aaa000000000000000000001') }
  let(:object_id_b) { double('BSON::ObjectId', to_s: 'bbb000000000000000000001') }

  let(:doc_a) do
    { '_id' => object_id_a, 'task_name' => 'db:migrate', 'status' => 'success',
      'started_at' => '2026-06-01T12:00:00Z', 'duration_ms' => 100,
      'hostname' => 'host-a', 'rails_env' => 'production' }
  end
  let(:doc_b) do
    { '_id' => object_id_b, 'task_name' => 'cache:clear', 'status' => 'failure',
      'started_at' => '2026-06-01T11:00:00Z', 'duration_ms' => 200,
      'hostname' => 'host-b', 'rails_env' => 'staging' }
  end

  describe '#query' do
    before { require 'kaminari' }

    let(:cursor) { [doc_a, doc_b] }
    let(:chainable) { instance_double('Mongo::Collection::View') }

    before do
      allow(collection).to receive(:count_documents).and_return(2)
      allow(collection).to receive(:find).and_return(chainable)
      allow(chainable).to receive(:sort).and_return(chainable)
      allow(chainable).to receive(:skip).and_return(chainable)
      allow(chainable).to receive(:limit).and_return(chainable)
      allow(chainable).to receive(:map) { |&blk| cursor.map(&blk) }
    end

    it 'returns ExecutionRecord instances' do
      result = adapter.query
      expect(result.first).to be_a(RakeAudit::Adapters::ExecutionRecord)
    end

    it 'passes the filter to find' do
      expect(collection).to receive(:find).with(hash_including('status' => 'failure')).and_return(chainable)
      adapter.query(filters: { status: 'failure' })
    end

    it 'paginates with the correct skip and limit' do
      expect(chainable).to receive(:skip).with(25).and_return(chainable)
      expect(chainable).to receive(:limit).with(25).and_return(chainable)
      adapter.query(page: 2, per_page: 25)
    end

    it 'exposes total_count from count_documents' do
      allow(collection).to receive(:count_documents).and_return(42)
      result = adapter.query
      expect(result.total_count).to eq(42)
    end
  end

  describe '#find' do
    # Stub the BSON namespace so these specs run without the bson gem installed.
    let(:fake_oid) { double('BSON::ObjectId') }

    before do
      stub_const('BSON', Module.new)
      stub_const('BSON::ObjectId', double('BSON::ObjectId class', from_string: fake_oid))
    end

    it 'raises RecordNotFound when no document matches' do
      allow(collection).to receive(:find).and_return(double(first: nil))
      expect { adapter.find('abc123') }.to raise_error(RakeAudit::RecordNotFound)
    end

    it 'raises RecordNotFound for an invalid ObjectId string' do
      allow(BSON::ObjectId).to receive(:from_string).and_raise(ArgumentError, 'invalid')
      expect { adapter.find('not-a-valid-id') }.to raise_error(RakeAudit::RecordNotFound)
    end
  end

  describe '#count' do
    it 'delegates to count_documents with an empty filter' do
      expect(collection).to receive(:count_documents).with({}).and_return(7)
      expect(adapter.count).to eq(7)
    end
  end

  describe '#count_by_status' do
    it 'delegates to count_documents with a status filter' do
      expect(collection).to receive(:count_documents).with('status' => 'failure').and_return(3)
      expect(adapter.count_by_status('failure')).to eq(3)
    end
  end

  describe '#average_duration_ms' do
    it 'returns nil when the aggregate result is nil' do
      allow(collection).to receive(:aggregate).and_return(double(first: nil))
      expect(adapter.average_duration_ms).to be_nil
    end

    it 'returns the avg field from the aggregation result' do
      allow(collection).to receive(:aggregate).and_return(double(first: { 'avg' => 250.5 }))
      expect(adapter.average_duration_ms).to eq(250.5)
    end
  end

  describe '#top_failed_tasks' do
    it 'returns [task_name, count] pairs from the aggregation' do
      allow(collection).to receive(:aggregate).and_return([
                                                            { '_id' => 'db:migrate', 'count' => 5 },
                                                            { '_id' => 'cache:clear', 'count' => 2 }
                                                          ])
      expect(adapter.top_failed_tasks).to eq([['db:migrate', 5], ['cache:clear', 2]])
    end
  end
end
