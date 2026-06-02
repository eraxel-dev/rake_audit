# frozen_string_literal: true

require 'rake_audit/adapters/base'

RSpec.describe RakeAudit::Adapters::Base do
  subject(:adapter) { described_class.new }

  {
    save: [nil],
    query: [],
    find: [1],
    count: [],
    count_by_status: ['success'],
    average_duration_ms: [],
    top_failed_tasks: []
  }.each do |method_name, args|
    it "#{method_name} raises NotImplementedError" do
      expect { adapter.public_send(method_name, *args) }
        .to raise_error(NotImplementedError, /#{Regexp.escape("#{described_class}##{method_name}")}/)
    end
  end

  describe '#stats' do
    it 'delegates to the five individual methods' do
      allow(adapter).to receive(:count).and_return(10)
      allow(adapter).to receive(:count_by_status).with('success').and_return(7)
      allow(adapter).to receive(:count_by_status).with('failure').and_return(3)
      allow(adapter).to receive(:average_duration_ms).and_return(250.0)
      allow(adapter).to receive(:top_failed_tasks).and_return([['task:a', 3]])

      expect(adapter.stats).to eq(
        total: 10,
        success_count: 7,
        failure_count: 3,
        average_duration_ms: 250.0,
        top_failed_tasks: [['task:a', 3]]
      )
    end
  end
end
