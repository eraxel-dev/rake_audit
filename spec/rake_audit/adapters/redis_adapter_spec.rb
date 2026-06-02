# frozen_string_literal: true

require 'rake_audit/adapters/redis_adapter'

RSpec.describe RakeAudit::Adapters::RedisAdapter do
  let(:redis_client) { instance_double('Redis') }
  subject(:adapter)  { described_class.new(client: redis_client) }

  let(:base_record_hash) { { task_name: 'cache:clear', status: 'success' } }
  let(:record) { instance_double(RakeAudit::TaskExecutionRecord, to_h: base_record_hash) }

  it 'inherits from Base' do
    expect(described_class.ancestors).to include(RakeAudit::Adapters::Base)
  end

  describe '#save' do
    it 'LPUSHes JSON containing the record fields and a generated id' do
      expect(redis_client).to receive(:lpush) do |key, json|
        data = JSON.parse(json, symbolize_names: true)
        expect(key).to eq('rake_audit:executions')
        expect(data).to include(**base_record_hash)
        expect(data[:id]).to be_a(String).and(match(/\A[0-9a-f-]{36}\z/))
      end
      adapter.save(record)
    end

    it 'generates a distinct id for each save' do
      ids = []
      allow(redis_client).to receive(:lpush) do |_key, json|
        ids << JSON.parse(json)['id']
      end
      2.times { adapter.save(record) }
      expect(ids.uniq.size).to eq(2)
    end
  end

  # --- query helpers -------------------------------------------------------

  let(:now) { Time.new(2026, 6, 1, 12, 0, 0) }
  let(:raw_records) do
    [
      { id: 'aaa', task_name: 'db:migrate', status: 'success',
        started_at: (now - 10).iso8601, duration_ms: 100,
        hostname: 'host-a', rails_env: 'production' }.to_json,
      { id: 'bbb', task_name: 'cache:clear', status: 'failure',
        started_at: (now - 20).iso8601, duration_ms: 200,
        hostname: 'host-b', rails_env: 'staging' }.to_json,
      { id: 'ccc', task_name: 'cache:clear', status: 'failure',
        started_at: (now - 30).iso8601, duration_ms: 300,
        hostname: 'host-a', rails_env: 'production' }.to_json
    ]
  end

  before do
    allow(redis_client).to receive(:lrange)
      .with('rake_audit:executions', 0, -1)
      .and_return(raw_records)
  end

  describe '#query' do
    before { require 'kaminari' }

    it 'returns records sorted by started_at descending' do
      result = adapter.query
      expect(result.map(&:id)).to eq(%w[aaa bbb ccc])
    end

    it 'filters by task_name' do
      result = adapter.query(filters: { task_name: 'db:migrate' })
      expect(result.map(&:id)).to eq(%w[aaa])
    end

    it 'filters by status' do
      result = adapter.query(filters: { status: 'failure' })
      expect(result.map(&:id)).to eq(%w[bbb ccc])
    end

    it 'filters by hostname' do
      result = adapter.query(filters: { hostname: 'host-b' })
      expect(result.map(&:id)).to eq(%w[bbb])
    end

    it 'filters by rails_env' do
      result = adapter.query(filters: { rails_env: 'production' })
      expect(result.map(&:id)).to eq(%w[aaa ccc])
    end

    it 'filters by date range (from/to)' do
      result = adapter.query(filters: { from: (now - 25).iso8601, to: (now - 5).iso8601 })
      expect(result.map(&:id)).to eq(%w[aaa bbb])
    end

    it 'paginates using per_page' do
      result = adapter.query(page: 1, per_page: 2)
      expect(result.size).to eq(2)
      expect(result.total_count).to eq(3)
    end

    it 'returns the second page' do
      result = adapter.query(page: 2, per_page: 2)
      expect(result.map(&:id)).to eq(%w[ccc])
    end

    it 'returns ExecutionRecord instances' do
      result = adapter.query
      expect(result.first).to be_a(RakeAudit::Adapters::ExecutionRecord)
    end
  end

  describe '#find' do
    it 'returns the matching ExecutionRecord' do
      rec = adapter.find('bbb')
      expect(rec).to be_a(RakeAudit::Adapters::ExecutionRecord)
      expect(rec.task_name).to eq('cache:clear')
    end

    it 'raises RecordNotFound for an unknown id' do
      expect { adapter.find('zzz') }.to raise_error(RakeAudit::RecordNotFound)
    end
  end

  describe '#count' do
    it 'returns the total number of records' do
      expect(adapter.count).to eq(3)
    end
  end

  describe '#count_by_status' do
    it 'counts successes' do
      expect(adapter.count_by_status('success')).to eq(1)
    end

    it 'counts failures' do
      expect(adapter.count_by_status('failure')).to eq(2)
    end
  end

  describe '#average_duration_ms' do
    it 'returns the mean duration' do
      expect(adapter.average_duration_ms).to be_within(0.01).of(200.0)
    end

    it 'returns nil when there are no records' do
      allow(redis_client).to receive(:lrange).and_return([])
      expect(adapter.average_duration_ms).to be_nil
    end
  end

  describe '#top_failed_tasks' do
    it 'returns task names ordered by failure count descending' do
      result = adapter.top_failed_tasks
      expect(result).to eq([['cache:clear', 2]])
    end

    it 'respects the limit' do
      result = adapter.top_failed_tasks(limit: 1)
      expect(result.size).to eq(1)
    end
  end

  describe '#stats' do
    it 'reads all_records exactly once' do
      expect(redis_client).to receive(:lrange).once.and_return(raw_records)
      adapter.stats
    end

    it 'returns all five metrics computed from a single pass' do
      result = adapter.stats
      expect(result[:total]).to eq(3)
      expect(result[:success_count]).to eq(1)
      expect(result[:failure_count]).to eq(2)
      expect(result[:average_duration_ms]).to be_within(0.01).of(200.0)
      expect(result[:top_failed_tasks]).to eq([['cache:clear', 2]])
    end

    it 'returns nil average when there are no records' do
      allow(redis_client).to receive(:lrange).and_return([])
      expect(adapter.stats[:average_duration_ms]).to be_nil
    end
  end
end
