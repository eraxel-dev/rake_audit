# frozen_string_literal: true

require 'spec_helper'

# Drive the full Web UI through a mounted Engine in a minimal Rails app. The
# support file is required lazily so the rest of the suite is unaffected when the
# Action Pack / Rack::Test dependencies are absent.
begin
  require 'rack/test'
  require_relative '../support/web_ui_app'
  WEB_UI_AVAILABLE = true
rescue LoadError => e
  warn "Web UI specs skipped: #{e.message}"
  WEB_UI_AVAILABLE = false
end

RSpec.describe 'RakeAudit Web UI', :active_record, if: WEB_UI_AVAILABLE do
  include Rack::Test::Methods
  include WebUiAppHelpers

  describe 'routing (Engine mounted at /rake_audit)' do
    it 'GET /rake_audit routes to executions#index' do
      get '/rake_audit'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include('Executions')
    end

    it 'GET /rake_audit/dashboard routes to dashboard#index' do
      get '/rake_audit/dashboard'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include('Dashboard')
    end

    it 'GET /rake_audit/executions routes to executions#index' do
      get '/rake_audit/executions'
      expect(last_response.status).to eq(200)
    end

    it 'GET /rake_audit/executions/:id routes to executions#show' do
      execution = create_execution
      get "/rake_audit/executions/#{execution.id}"
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include("Execution ##{execution.id}")
    end
  end

  describe 'dashboard#index' do
    before do
      create_execution(task_name: 'a', status: 'success', duration_ms: 100)
      create_execution(task_name: 'b', status: 'success', duration_ms: 300)
      create_execution(task_name: 'b', status: 'failure', duration_ms: 200)
      create_execution(task_name: 'c', status: 'failure', duration_ms: 400)
      create_execution(task_name: 'c', status: 'failure', duration_ms: 600)
      get '/rake_audit/dashboard'
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

    it 'shows the correct totals' do
      body = last_response.body
      expect(body).to include('>5<')   # total
      expect(body).to include('>2<')   # success count
      expect(body).to include('>3<')   # failure count
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

  describe 'executions#index filtering and pagination' do
    it 'is ordered by started_at descending' do
      old = create_execution(task_name: 'old', started_at: Time.now - 100)
      recent = create_execution(task_name: 'recent', started_at: Time.now - 1)
      get '/rake_audit/executions'
      body = last_response.body
      expect(body.index(recent.task_name)).to be < body.index(old.task_name)
    end

    it 'filters by task_name' do
      create_execution(task_name: 'keep:me')
      create_execution(task_name: 'drop:me')
      get '/rake_audit/executions', task_name: 'keep:me'
      body = last_response.body
      expect(body).to include('keep:me')
      expect(body).not_to include('drop:me')
    end

    it 'filters by status' do
      create_execution(task_name: 'ok', status: 'success')
      create_execution(task_name: 'bad', status: 'failure')
      get '/rake_audit/executions', status: 'failure'
      body = last_response.body
      expect(body).to include('bad')
      expect(body).not_to include('>ok<')
    end

    it 'filters by hostname' do
      create_execution(task_name: 'host:keep', hostname: 'alpha')
      create_execution(task_name: 'host:drop', hostname: 'beta')
      get '/rake_audit/executions', hostname: 'alpha'
      body = last_response.body
      expect(body).to include('host:keep')
      expect(body).not_to include('host:drop')
    end

    it 'filters by rails_env' do
      create_execution(task_name: 'e1', rails_env: 'production')
      create_execution(task_name: 'e2', rails_env: 'staging')
      get '/rake_audit/executions', rails_env: 'production'
      body = last_response.body
      expect(body).to include('e1')
      expect(body).not_to include('e2')
    end

    it 'filters by date range (from/to)' do
      create_execution(task_name: 'in:range', started_at: Time.new(2026, 5, 15, 12))
      create_execution(task_name: 'too:old', started_at: Time.new(2026, 1, 1, 12))
      create_execution(task_name: 'too:new', started_at: Time.new(2026, 12, 1, 12))
      get '/rake_audit/executions', from: '2026-05-01', to: '2026-06-01'
      body = last_response.body
      expect(body).to include('in:range')
      expect(body).not_to include('too:old')
      expect(body).not_to include('too:new')
    end

    it 'paginates the result set' do
      30.times { |i| create_execution(task_name: "task#{i}", started_at: Time.now - i) }
      get '/rake_audit/executions'
      # Kaminari's default page size is 25, so not all 30 appear on page 1.
      expect(last_response.body).not_to include('task29')
      get '/rake_audit/executions', page: 2
      expect(last_response.body).to include('task29')
    end
  end

  describe 'executions#show sections' do
    it 'shows all five sections for a failed execution' do
      execution = create_execution(
        status: 'failure',
        error_class: 'RuntimeError',
        error_message: 'kaboom',
        arguments: { 'env' => 'prod' }
      )
      get "/rake_audit/executions/#{execution.id}"
      body = last_response.body
      expect(body).to include('Task Info')
      expect(body).to include('Arguments')
      expect(body).to include('Execution Info')
      expect(body).to include('Error Info')
      expect(body).to include('Environment Info')
      expect(body).to include('RuntimeError')
      expect(body).to include('kaboom')
      expect(body).to include('prod')
    end

    it 'hides the Error Info section for a successful execution' do
      execution = create_execution(status: 'success')
      get "/rake_audit/executions/#{execution.id}"
      body = last_response.body
      expect(body).to include('Task Info')
      expect(body).to include('Environment Info')
      expect(body).not_to include('Error Info')
    end
  end

  describe 'authentication hook' do
    after { RakeAudit.reset_config! }

    it 'is a no-op when authenticate_with is nil (pages public)' do
      RakeAudit.config.authenticate_with = nil
      get '/rake_audit/executions'
      expect(last_response.status).to eq(200)
    end

    it 'runs the configured authenticate_with as a before_action' do
      called = false
      RakeAudit.config.authenticate_with = ->(_controller) { called = true }
      get '/rake_audit/executions'
      expect(called).to be(true)
    end

    it 'lets the auth block halt the request via the controller' do
      RakeAudit.config.authenticate_with = lambda { |controller|
        controller.head(:forbidden)
      }
      get '/rake_audit/executions'
      expect(last_response.status).to eq(403)
    end
  end
end
