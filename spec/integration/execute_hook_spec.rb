# frozen_string_literal: true

require 'spec_helper'

# End-to-end integration of the execute hook: a *real* Rake task, defined and
# invoked through the prepended {RakeAudit::TaskPatch}, with a stub adapter
# capturing the persisted {RakeAudit::TaskExecutionRecord}.
#
# Unlike the unit specs (which exercise ExecutionRecorder in isolation), this
# drives the full path: Rake::Task#execute -> TaskPatch -> ExecutionRecorder ->
# builder -> adapter. No database or external service is involved; the adapter
# is an in-memory capture, satisfying the "runs without external services"
# guarantee while still proving the hook is wired correctly.
RSpec.describe 'execute hook (integration)' do
  # Each example gets a fresh Rake application so task definitions never leak
  # between examples and the suite stays order-independent.
  around do |example|
    previous = Rake.application
    Rake.application = Rake::Application.new
    example.run
    Rake.application = previous
  end

  let(:adapter) { MemoryAdapter.new }

  before { RakeAudit.configure { |c| c.adapter = adapter } }

  # @return [RakeAudit::TaskExecutionRecord] the single captured record.
  def last_record
    expect(adapter.saved.size).to eq(1)
    adapter.saved.first
  end

  describe 'a successful task' do
    before do
      Rake::Task.define_task('test:task') { :did_work }
      Rake::Task['test:task'].execute
    end

    it 'saves a record with status "success"' do
      expect(last_record.status).to eq('success')
    end

    it 'captures the task name' do
      expect(last_record.task_name).to eq('test:task')
    end

    it 'records a non-negative integer duration_ms' do
      expect(last_record.duration_ms).to be_a(Integer)
      expect(last_record.duration_ms).to be >= 0
    end

    it 'leaves the error fields nil' do
      expect(last_record.error_class).to be_nil
      expect(last_record.error_message).to be_nil
    end
  end

  describe 'a failing task' do
    before do
      Rake::Task.define_task('test:boom') { raise 'boom' }
    end

    it 're-raises the original exception to the caller' do
      expect { Rake::Task['test:boom'].execute }
        .to raise_error(RuntimeError, 'boom')
    end

    it 'still saves a failure record with populated error fields' do
      Rake::Task['test:boom'].execute
    rescue RuntimeError
      record = last_record
      expect(record.status).to eq('failure')
      expect(record.error_class).to eq('RuntimeError')
      expect(record.error_message).to eq('boom')
    end
  end

  describe 'an adapter error during save' do
    let(:logger) { instance_double(Logger) }

    before do
      RakeAudit.configure do |c|
        c.adapter = ExplodingAdapter.new
        c.logger = logger
      end
    end

    it 'does not propagate the adapter error and leaves the task result intact' do
      allow(logger).to receive(:error)
      side_effect = []
      Rake::Task.define_task('test:ok') { side_effect << :ran }

      expect { Rake::Task['test:ok'].execute }.not_to raise_error
      expect(side_effect).to eq([:ran])
    end

    it 'logs the save failure' do
      expect(logger).to receive(:error).with(/\[RakeAudit\] Save failed/)
      Rake::Task.define_task('test:ok') { :done }
      Rake::Task['test:ok'].execute
    end
  end
end
