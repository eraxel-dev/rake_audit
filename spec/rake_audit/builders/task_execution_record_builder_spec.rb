# frozen_string_literal: true

RSpec.describe RakeAudit::Builders::TaskExecutionRecordBuilder do
  let(:config) { RakeAudit::Configuration.new }
  let(:task) { instance_double('Rake::Task', name: 'reports:generate') }
  let(:started_at) { Time.at(1_000) }
  let(:finished_at) { Time.at(1_000.25) }

  def build(exception: nil, args: nil)
    described_class.build(
      task: task,
      args: args,
      started_at: started_at,
      finished_at: finished_at,
      exception: exception,
      config: config
    )
  end

  describe 'success path' do
    subject(:record) { build }

    it 'sets the task name' do
      expect(record.task_name).to eq('reports:generate')
    end

    it 'marks status success and leaves error fields nil' do
      expect(record.status).to eq('success')
      expect(record.error_class).to be_nil
      expect(record.error_message).to be_nil
    end

    it 'computes duration in whole milliseconds' do
      expect(record.duration_ms).to eq(250)
    end
  end

  describe 'failure path' do
    subject(:record) { build(exception: ArgumentError.new('bad input')) }

    it 'marks status failure with error class and message' do
      expect(record.status).to eq('failure')
      expect(record.error_class).to eq('ArgumentError')
      expect(record.error_message).to eq('bad input')
    end
  end

  describe 'argument normalization' do
    it 'uses to_hash when available (Rake::TaskArguments-like)' do
      args = instance_double('Rake::TaskArguments', to_hash: { name: 'value' })
      expect(build(args: args).arguments).to eq({ name: 'value' })
    end

    it 'passes through a plain Hash' do
      expect(build(args: { a: 1 }).arguments).to eq({ a: 1 })
    end

    it 'defaults to an empty Hash for nil' do
      expect(build(args: nil).arguments).to eq({})
    end
  end

  describe 'environment capture flags' do
    it 'captures environment fields when enabled' do
      record = build
      expect(record.hostname).to be_a(String)
      expect(record.pid).to eq(Process.pid)
      expect(record.ruby_version).to eq(RUBY_VERSION)
    end

    it 'omits environment fields when disabled' do
      config.capture_hostname = false
      config.capture_pid = false
      config.capture_ruby_version = false
      config.capture_rails_env = false

      record = build
      expect(record.hostname).to be_nil
      expect(record.pid).to be_nil
      expect(record.ruby_version).to be_nil
      expect(record.rails_env).to be_nil
    end
  end
end
