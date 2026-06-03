# frozen_string_literal: true

require_relative 'system_helper'

# System coverage for the executions list page: columns, the filter form, result
# ordering, and pagination.
RSpec.describe 'Executions index page', :active_record, if: SYSTEM_SPECS_AVAILABLE do
  include Rack::Test::Methods
  include WebUiAppHelpers

  before { RakeAudit.config.adapter = RakeAudit::Adapters::ActiveRecordAdapter.new }
  after  { RakeAudit.reset_config! }

  describe 'columns and filter form' do
    before do
      create_execution(task_name: 'db:migrate', status: 'success', hostname: 'host-a')
      get '/rake_audit/executions'
    end

    it 'returns a successful response' do
      expect(last_response.status).to eq(200)
    end

    it 'renders the column headers' do
      body = last_response.body
      expect(body).to include('Task')
      expect(body).to include('Status')
      expect(body).to include('Started')
    end

    it 'renders the filter form fields' do
      body = last_response.body
      expect(body).to include('task_name')
      expect(body).to include('status')
      expect(body).to include('hostname')
    end
  end

  describe 'ordering' do
    it 'lists executions by started_at descending' do
      old    = create_execution(task_name: 'old',    started_at: Time.now - 100)
      recent = create_execution(task_name: 'recent', started_at: Time.now - 1)
      get '/rake_audit/executions'
      body = last_response.body
      expect(body.index(recent.task_name)).to be < body.index(old.task_name)
    end
  end

  describe 'filtering' do
    it 'filters by task_name' do
      create_execution(task_name: 'keep:me')
      create_execution(task_name: 'drop:me')
      get '/rake_audit/executions', task_name: 'keep:me'
      body = last_response.body
      expect(body).to include('keep:me')
      expect(body).not_to include('drop:me')
    end

    it 'filters by status' do
      create_execution(task_name: 'ok',  status: 'success')
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

    it 'filters by a date range' do
      create_execution(task_name: 'in:range', started_at: Time.new(2026, 5, 15, 12))
      create_execution(task_name: 'too:old',  started_at: Time.new(2026, 1, 1, 12))
      create_execution(task_name: 'too:new',  started_at: Time.new(2026, 12, 1, 12))
      get '/rake_audit/executions', from: '2026-05-01', to: '2026-06-01'
      body = last_response.body
      expect(body).to include('in:range')
      expect(body).not_to include('too:old')
      expect(body).not_to include('too:new')
    end
  end

  describe 'pagination' do
    it 'splits results across pages (Kaminari default of 25 per page)' do
      30.times { |i| create_execution(task_name: "task#{i}", started_at: Time.now - i) }

      get '/rake_audit/executions'
      expect(last_response.body).not_to include('task29')

      get '/rake_audit/executions', page: 2
      expect(last_response.body).to include('task29')
    end
  end
end
