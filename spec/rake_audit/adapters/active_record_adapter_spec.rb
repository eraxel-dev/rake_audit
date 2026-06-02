# frozen_string_literal: true

require 'rake_audit/adapters/active_record_adapter'

RSpec.describe RakeAudit::Adapters::ActiveRecordAdapter do
  subject(:adapter) { described_class.new }

  it 'inherits from Base' do
    expect(described_class.ancestors).to include(RakeAudit::Adapters::Base)
  end

  # --- #save (unit, stubbed AR) --------------------------------------------

  describe '#save' do
    let(:record_hash) { { task_name: 'db:migrate', status: 'success', arguments: {} } }
    let(:record) { instance_double(RakeAudit::TaskExecutionRecord, to_h: record_hash) }

    before do
      stub_const('RakeAudit::TaskExecution', Class.new { def self.create!(_attrs); end })
    end

    it 'calls TaskExecution.create! with record.to_h' do
      expect(RakeAudit::TaskExecution).to receive(:create!).with(record_hash)
      adapter.save(record)
    end
  end

  # --- query methods (integration, real SQLite DB) -------------------------

  describe 'query methods', :active_record do
    def make_execution(attrs = {})
      defaults = {
        task_name: 'default:task', status: 'success',
        started_at: Time.now - 5, finished_at: Time.now,
        duration_ms: 100, hostname: 'h1', rails_env: 'test'
      }
      RakeAudit::TaskExecution.create!(defaults.merge(attrs))
    end

    describe '#query' do
      before { require 'kaminari' }

      it 'returns records sorted by started_at descending' do
        old    = make_execution(task_name: 'old',    started_at: Time.now - 100)
        recent = make_execution(task_name: 'recent', started_at: Time.now - 1)
        result = adapter.query
        expect(result.map(&:id)).to eq([recent.id, old.id])
      end

      it 'filters by task_name' do
        make_execution(task_name: 'keep:me')
        make_execution(task_name: 'drop:me')
        result = adapter.query(filters: { task_name: 'keep:me' })
        expect(result.map(&:task_name)).to all(eq('keep:me'))
        expect(result.size).to eq(1)
      end

      it 'filters by status' do
        make_execution(task_name: 'ok',  status: 'success')
        make_execution(task_name: 'bad', status: 'failure')
        result = adapter.query(filters: { status: 'failure' })
        expect(result.map(&:task_name)).to all(eq('bad'))
      end

      it 'filters by hostname' do
        make_execution(task_name: 'a', hostname: 'alpha')
        make_execution(task_name: 'b', hostname: 'beta')
        result = adapter.query(filters: { hostname: 'alpha' })
        expect(result.map(&:task_name)).to eq(['a'])
      end

      it 'filters by rails_env' do
        make_execution(task_name: 'prod', rails_env: 'production')
        make_execution(task_name: 'stg',  rails_env: 'staging')
        result = adapter.query(filters: { rails_env: 'production' })
        expect(result.map(&:task_name)).to eq(['prod'])
      end

      it 'filters by date range' do
        make_execution(task_name: 'in',  started_at: Time.new(2026, 5, 15))
        make_execution(task_name: 'old', started_at: Time.new(2026, 1, 1))
        result = adapter.query(filters: { from: '2026-05-01', to: '2026-06-01' })
        expect(result.map(&:task_name)).to eq(['in'])
      end

      it 'paginates correctly' do
        30.times { |i| make_execution(task_name: "t#{i}", started_at: Time.now - i) }
        page1 = adapter.query(page: 1, per_page: 25)
        page2 = adapter.query(page: 2, per_page: 25)
        expect(page1.size).to eq(25)
        expect(page2.size).to eq(5)
        expect(page1.total_count).to eq(30)
      end
    end

    describe '#find' do
      it 'returns the matching TaskExecution' do
        ex = make_execution
        expect(adapter.find(ex.id)).to eq(ex)
      end

      it 'raises RecordNotFound for a missing id' do
        expect { adapter.find(99_999) }.to raise_error(RakeAudit::RecordNotFound)
      end
    end

    describe '#count' do
      it 'returns the total number of executions' do
        3.times { make_execution }
        expect(adapter.count).to eq(3)
      end
    end

    describe '#count_by_status' do
      it 'counts by status' do
        2.times { make_execution(status: 'success') }
        make_execution(status: 'failure')
        expect(adapter.count_by_status('success')).to eq(2)
        expect(adapter.count_by_status('failure')).to eq(1)
      end
    end

    describe '#average_duration_ms' do
      it 'returns the mean duration' do
        make_execution(duration_ms: 100)
        make_execution(duration_ms: 300)
        expect(adapter.average_duration_ms).to be_within(0.01).of(200.0)
      end

      it 'returns nil when there are no records' do
        expect(adapter.average_duration_ms).to be_nil
      end
    end

    describe '#top_failed_tasks' do
      it 'returns task names ordered by failure count descending' do
        2.times { make_execution(task_name: 'a', status: 'failure') }
        make_execution(task_name: 'b', status: 'failure')
        result = adapter.top_failed_tasks
        expect(result).to eq([['a', 2], ['b', 1]])
      end

      it 'respects the limit' do
        3.times { |i| make_execution(task_name: "t#{i}", status: 'failure') }
        expect(adapter.top_failed_tasks(limit: 2).size).to eq(2)
      end
    end

    describe '#stats' do
      it 'returns all five metrics' do
        2.times { make_execution(task_name: 'x', status: 'success', duration_ms: 100) }
        make_execution(task_name: 'x', status: 'failure', duration_ms: 300)
        result = adapter.stats
        expect(result[:total]).to eq(3)
        expect(result[:success_count]).to eq(2)
        expect(result[:failure_count]).to eq(1)
        expect(result[:average_duration_ms]).to be_within(0.01).of(166.67)
        expect(result[:top_failed_tasks]).to eq([['x', 1]])
      end
    end
  end
end
