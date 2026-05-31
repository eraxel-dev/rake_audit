# frozen_string_literal: true

require 'rake'
require 'rake_audit'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  # Ensure every example starts from a clean configuration.
  config.before do
    RakeAudit.reset_config!
  end
end

# A minimal in-memory adapter used across specs to capture saved records.
class MemoryAdapter
  attr_reader :saved

  def initialize
    @saved = []
  end

  def save(record)
    @saved << record
  end
end

# An adapter whose #save always raises, to exercise error-silencing behavior.
class ExplodingAdapter
  def save(_record)
    raise 'boom from adapter'
  end
end
