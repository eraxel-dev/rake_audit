# frozen_string_literal: true

RSpec.describe RakeAudit::TaskPatch do
  let(:adapter) { MemoryAdapter.new }

  around do |example|
    Rake.application = Rake::Application.new
    example.run
    Rake.application = Rake::Application.new
  end

  before { RakeAudit.configure { |c| c.adapter = adapter } }

  it 'is prepended into Rake::Task' do
    expect(Rake::Task.ancestors.index(described_class))
      .to be < Rake::Task.ancestors.index(Rake::Task)
  end

  it 'records a successful task execution' do
    Rake::Task.define_task(:ok_task) { :done }
    Rake::Task[:ok_task].execute

    expect(adapter.saved.size).to eq(1)
    record = adapter.saved.first
    expect(record.task_name).to eq('ok_task')
    expect(record.status).to eq('success')
  end

  it 'records a failed task and re-raises the original exception' do
    Rake::Task.define_task(:bad_task) { raise 'task blew up' }

    expect { Rake::Task[:bad_task].execute }
      .to raise_error(RuntimeError, 'task blew up')

    record = adapter.saved.first
    expect(record.status).to eq('failure')
    expect(record.error_class).to eq('RuntimeError')
    expect(record.error_message).to eq('task blew up')
  end

  it "does not alter the task's normal behavior" do
    side_effect = []
    Rake::Task.define_task(:effect_task) { side_effect << :ran }
    Rake::Task[:effect_task].execute
    expect(side_effect).to eq([:ran])
  end
end
