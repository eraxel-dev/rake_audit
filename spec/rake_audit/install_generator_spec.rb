# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'

require 'rails'
require 'rails/generators'
require_relative '../../lib/generators/rake_audit/install_generator'

RSpec.describe RakeAudit::Generators::InstallGenerator do
  around do |example|
    Dir.mktmpdir('rake_audit_generator') do |dir|
      @destination = dir
      example.run
    end
  end

  def run_generator
    described_class.start([], destination_root: @destination)
  end

  it 'creates the initializer in config/initializers' do
    run_generator
    initializer = File.join(@destination, 'config/initializers/rake_audit.rb')
    expect(File.exist?(initializer)).to be(true)
    expect(File.read(initializer)).to include('RakeAudit.configure do |config|')
    expect(File.read(initializer)).to include('# config.adapter =')
  end

  it 'creates a timestamped migration in db/migrate' do
    run_generator
    migrations = Dir.glob(
      File.join(@destination, 'db/migrate/*_create_rake_task_executions.rb')
    )
    expect(migrations.size).to eq(1)

    basename = File.basename(migrations.first)
    expect(basename).to match(/\A\d{14}_create_rake_task_executions\.rb\z/)
  end

  it 'writes a migration that defines the table and indexes' do
    run_generator
    migration = Dir.glob(
      File.join(@destination, 'db/migrate/*_create_rake_task_executions.rb')
    ).first
    contents = File.read(migration)

    expect(contents).to include('create_table :rake_task_executions')
    expect(contents).to include('add_index :rake_task_executions, %i[task_name started_at]')
    expect(contents).to include('add_index :rake_task_executions, %i[status started_at]')
    expect(contents).to match(/ActiveRecord::Migration\[\d+\.\d+\]/)
  end
end
