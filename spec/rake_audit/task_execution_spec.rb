# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe RakeAudit::TaskExecution, :active_record do
  let(:valid_attributes) do
    {
      task_name: 'db:migrate',
      status: 'success',
      started_at: Time.now,
      finished_at: Time.now
    }
  end

  it 'maps to the rake_task_executions table' do
    expect(described_class.table_name).to eq('rake_task_executions')
  end

  it 'persists a valid record with the twelve adapter fields' do
    record = described_class.create!(
      valid_attributes.merge(
        arguments: { 'verbose' => true },
        duration_ms: 1234,
        error_class: nil,
        error_message: nil,
        hostname: 'host-1',
        pid: 4242,
        ruby_version: RUBY_VERSION,
        rails_env: 'test'
      )
    )
    expect(record).to be_persisted
    expect(described_class.count).to eq(1)
  end

  it 'round-trips arguments as a Hash on SQLite text columns' do
    record = described_class.create!(
      valid_attributes.merge(arguments: { 'verbose' => true, 'count' => 3 })
    )
    reloaded = described_class.find(record.id)
    expect(reloaded.arguments).to eq('verbose' => true, 'count' => 3)
    expect(reloaded.arguments).to be_a(Hash)
  end

  it 'stores arguments as valid JSON, not a stringified Ruby hash' do
    described_class.create!(valid_attributes.merge(arguments: { 'k' => 'v' }))
    raw = described_class.connection.select_value(
      'SELECT arguments FROM rake_task_executions LIMIT 1'
    )
    expect { JSON.parse(raw) }.not_to raise_error
    expect(JSON.parse(raw)).to eq('k' => 'v')
  end

  it 'accepts exactly the hash produced by TaskExecutionRecord#to_h' do
    payload = RakeAudit::TaskExecutionRecord.new(
      task_name: 'app:build',
      arguments: { 'env' => 'ci' },
      started_at: Time.now,
      finished_at: Time.now,
      duration_ms: 10,
      status: 'success',
      error_class: nil,
      error_message: nil,
      hostname: 'h',
      pid: 1,
      ruby_version: RUBY_VERSION,
      rails_env: 'test'
    ).to_h

    expect { described_class.create!(payload) }.not_to raise_error
  end

  describe 'validations' do
    it 'is valid with all required attributes present' do
      expect(described_class.new(valid_attributes)).to be_valid
    end

    %i[task_name status started_at finished_at].each do |attribute|
      it "requires #{attribute} to be present" do
        record = described_class.new(valid_attributes.except(attribute))
        expect(record).not_to be_valid
        expect(record.errors[attribute]).to include("can't be blank")
      end
    end
  end
end
