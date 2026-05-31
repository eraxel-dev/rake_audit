# frozen_string_literal: true

require_relative 'rake_audit/version'
require_relative 'rake_audit/configuration'
require_relative 'rake_audit/task_execution_record'
require_relative 'rake_audit/builders/task_execution_record_builder'
require_relative 'rake_audit/execution_recorder'
require_relative 'rake_audit/task_patch'

# Top-level namespace and public entry point for the gem.
#
# Typical usage:
#
#   RakeAudit.configure do |c|
#     c.adapter = MyAdapter.new
#   end
#
# Loading this file also installs the {RakeAudit::TaskPatch} into +Rake::Task+
# when Rake is available, so task execution is recorded automatically.
module RakeAudit
  # Error namespace base class for the gem.
  class Error < StandardError; end

  class << self
    # The current configuration, created on first access.
    #
    # @return [RakeAudit::Configuration]
    def config
      @config ||= Configuration.new
    end

    alias configuration config

    # Yield the configuration for mutation.
    #
    #   RakeAudit.configure { |c| c.adapter = MyAdapter.new }
    #
    # @yieldparam config [RakeAudit::Configuration]
    # @return [RakeAudit::Configuration]
    def configure
      yield config if block_given?
      config
    end

    # Reset configuration to defaults. Primarily useful in tests.
    #
    # @return [RakeAudit::Configuration]
    def reset_config!
      @config = Configuration.new
    end

    # Install the execution hook into +Rake::Task+.
    #
    # Idempotent: prepending the same module twice is a no-op in Ruby, so this
    # is safe to call multiple times.
    #
    # @return [Boolean] true if Rake was present and the patch is installed.
    # rubocop:disable Naming/PredicateMethod
    def install!
      return false unless defined?(Rake::Task)

      Rake::Task.prepend(TaskPatch)
      true
    end
    # rubocop:enable Naming/PredicateMethod
  end
end

# Auto-install the patch when Rake is already loaded. When Rake loads later
# (e.g. a Railtie or the application's Rakefile), callers can invoke
# RakeAudit.install! explicitly.
RakeAudit.install!
