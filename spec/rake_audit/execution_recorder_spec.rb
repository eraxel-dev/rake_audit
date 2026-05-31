# frozen_string_literal: true

RSpec.describe RakeAudit::ExecutionRecorder do
  let(:task) { instance_double('Rake::Task', name: 'maintenance:run') }
  let(:adapter) { MemoryAdapter.new }

  def recorder
    described_class.new(task: task, args: nil)
  end

  describe '#record with a configured adapter' do
    before { RakeAudit.configure { |c| c.adapter = adapter } }

    it "returns the block's value on success" do
      expect(recorder.record { 123 }).to eq(123)
    end

    it 'saves a success record' do
      recorder.record { :ok }
      expect(adapter.saved.size).to eq(1)
      expect(adapter.saved.first.status).to eq('success')
    end

    it 're-raises the original exception unchanged' do
      boom = RuntimeError.new('explode')
      raised = nil
      begin
        recorder.record { raise boom }
      rescue RuntimeError => e
        raised = e
      end
      expect(raised).to be(boom)
    end

    it 'saves a failure record when the task raises' do
      begin
        recorder.record { raise ArgumentError, 'nope' }
      rescue ArgumentError
        # expected
      end
      record = adapter.saved.first
      expect(record.status).to eq('failure')
      expect(record.error_class).to eq('ArgumentError')
      expect(record.error_message).to eq('nope')
    end

    it 'records even when the block raises a low-level Exception' do
      begin
        recorder.record { raise NoMemoryError, 'oom' }
      rescue NoMemoryError
        # expected
      end
      expect(adapter.saved.first.status).to eq('failure')
      expect(adapter.saved.first.error_class).to eq('NoMemoryError')
    end
  end

  describe 'no-op when adapter is nil' do
    it 'does not attempt to save' do
      expect { recorder.record { :ok } }.not_to raise_error
    end

    it 'still returns the block value' do
      expect(recorder.record { 7 }).to eq(7)
    end
  end

  describe 'adapter error silencing' do
    let(:logger) { instance_double(Logger) }

    before do
      RakeAudit.configure do |c|
        c.adapter = ExplodingAdapter.new
        c.logger = logger
      end
    end

    it 'does not let adapter errors affect a successful task' do
      allow(logger).to receive(:error)
      expect(recorder.record { :ok }).to eq(:ok)
    end

    it 'logs the save failure' do
      expect(logger).to receive(:error).with(/\[RakeAudit\] Save failed/)
      recorder.record { :ok }
    end

    it "still re-raises the task's own exception when both fail" do
      allow(logger).to receive(:error)
      expect { recorder.record { raise 'task failure' } }
        .to raise_error(RuntimeError, 'task failure')
    end
  end
end
