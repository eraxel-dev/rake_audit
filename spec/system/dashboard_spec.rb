# frozen_string_literal: true

require_relative 'system_helper'

# System coverage for the dashboard page: it must render all six headline
# metrics computed from the persisted executions.
RSpec.describe 'Dashboard page', :active_record, if: SYSTEM_SPECS_AVAILABLE do
  include Rack::Test::Methods
  include WebUiAppHelpers

  before { RakeAudit.config.adapter = RakeAudit::Adapters::ActiveRecordAdapter.new }
  after  { RakeAudit.reset_config! }

  context 'with a mix of successful and failed executions' do
    before do
      create_execution(task_name: 'a', status: 'success', duration_ms: 100)
      create_execution(task_name: 'b', status: 'success', duration_ms: 300)
      create_execution(task_name: 'b', status: 'failure', duration_ms: 200)
      create_execution(task_name: 'c', status: 'failure', duration_ms: 400)
      create_execution(task_name: 'c', status: 'failure', duration_ms: 600)
      get '/rake_audit/dashboard'
    end

    it 'returns a successful response' do
      expect(last_response.status).to eq(200)
    end

    it 'renders all six metrics' do
      body = last_response.body
      expect(body).to include('Total')
      expect(body).to include('Success')
      expect(body).to include('Failure')
      expect(body).to include('Failure Rate')
      expect(body).to include('Avg Duration')
      expect(body).to include('Top 10 Failed Tasks')
    end

    it 'shows the correct total, success, and failure counts' do
      body = last_response.body
      expect(body).to include('>5<') # total
      expect(body).to include('>2<') # success count
      expect(body).to include('>3<') # failure count
    end

    it 'computes the failure rate as a percentage' do
      # 3 failures / 5 total = 60.0%
      expect(last_response.body).to include('60.0%')
    end

    it 'orders the top failed tasks by failure count descending' do
      body = last_response.body
      # "c" has 2 failures, "b" has 1 — "c" must appear before "b".
      expect(body.index('>c<')).to be < body.index('>b<')
    end
  end
end
