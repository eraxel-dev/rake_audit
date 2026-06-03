# frozen_string_literal: true

require_relative 'system_helper'

# System coverage for the execution detail page: all five information sections
# render, and the Error Info section is shown only for failed executions.
RSpec.describe 'Executions show page', :active_record, if: SYSTEM_SPECS_AVAILABLE do
  include Rack::Test::Methods
  include WebUiAppHelpers

  before { RakeAudit.config.adapter = RakeAudit::Adapters::ActiveRecordAdapter.new }
  after  { RakeAudit.reset_config! }

  describe 'a failed execution' do
    let(:execution) do
      create_execution(
        status: 'failure',
        error_class: 'RuntimeError',
        error_message: 'kaboom',
        arguments: { 'env' => 'prod' }
      )
    end

    before { get "/rake_audit/executions/#{execution.id}" }

    it 'returns a successful response' do
      expect(last_response.status).to eq(200)
    end

    it 'renders all five sections' do
      body = last_response.body
      expect(body).to include('Task Info')
      expect(body).to include('Arguments')
      expect(body).to include('Execution Info')
      expect(body).to include('Error Info')
      expect(body).to include('Environment Info')
    end

    it 'shows the error details' do
      body = last_response.body
      expect(body).to include('RuntimeError')
      expect(body).to include('kaboom')
    end

    it 'shows the captured arguments' do
      expect(last_response.body).to include('prod')
    end
  end

  describe 'a successful execution' do
    let(:execution) { create_execution(status: 'success') }

    before { get "/rake_audit/executions/#{execution.id}" }

    it 'renders the non-error sections' do
      body = last_response.body
      expect(body).to include('Task Info')
      expect(body).to include('Execution Info')
      expect(body).to include('Environment Info')
    end

    it 'hides the Error Info section' do
      expect(last_response.body).not_to include('Error Info')
    end
  end
end
