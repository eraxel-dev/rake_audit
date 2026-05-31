# frozen_string_literal: true

RSpec.describe RakeAudit::TaskExecutionRecord do
  let(:attributes) do
    {
      task_name: 'db:migrate',
      arguments: { 'version' => '1' },
      started_at: Time.at(0),
      finished_at: Time.at(1),
      duration_ms: 1000,
      status: 'success',
      error_class: nil,
      error_message: nil,
      hostname: 'host',
      pid: 42,
      ruby_version: '3.2.0',
      rails_env: 'test'
    }
  end

  subject(:record) { described_class.new(**attributes) }

  describe '#to_h' do
    it 'returns a plain Hash' do
      expect(record.to_h).to be_an_instance_of(Hash)
    end

    it 'includes all 12 fields' do
      expect(record.to_h.keys).to contain_exactly(
        :task_name, :arguments, :started_at, :finished_at, :duration_ms,
        :status, :error_class, :error_message, :hostname, :pid,
        :ruby_version, :rails_env
      )
      expect(record.to_h.size).to eq(12)
    end

    it 'round-trips every value' do
      expect(record.to_h).to eq(attributes)
    end
  end

  it 'supports keyword construction with partial fields' do
    partial = described_class.new(task_name: 'x', status: 'failure')
    expect(partial.task_name).to eq('x')
    expect(partial.status).to eq('failure')
    expect(partial.hostname).to be_nil
  end
end
