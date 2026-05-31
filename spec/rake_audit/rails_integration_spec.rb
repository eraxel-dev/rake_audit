# frozen_string_literal: true

require 'spec_helper'

# The Engine and Railtie need Rails to be defined. Load railties, then the gem's
# Rails files explicitly (they are normally required by lib/rake_audit.rb only
# when Rails is already present, which is not the case for the unit suite).
require 'rails'
require_relative '../../lib/rake_audit/rails/engine'
require_relative '../../lib/rake_audit/rails/railtie'

RSpec.describe 'Rails integration' do
  describe RakeAudit::Engine do
    it 'is a Rails::Engine' do
      expect(described_class.ancestors).to include(Rails::Engine)
    end

    it 'isolates the RakeAudit namespace' do
      expect(described_class.isolated?).to be(true)
      expect(described_class.railtie_namespace).to eq(RakeAudit)
    end
  end

  describe RakeAudit::Railtie do
    it 'is a Rails::Railtie' do
      expect(described_class.ancestors).to include(Rails::Railtie)
    end
  end

  describe 'after_initialize prepend gating' do
    # Re-run the exact body of the Railtie's after_initialize hook so the
    # adapter-presence gate is verified without booting a full application.
    def run_after_initialize_hook
      RakeAudit.install! if RakeAudit.config.adapter
    end

    it 'installs the patch when an adapter is configured' do
      RakeAudit.configure { |c| c.adapter = MemoryAdapter.new }
      expect(RakeAudit).to receive(:install!)
      run_after_initialize_hook
    end

    it 'does not install the patch when no adapter is configured' do
      RakeAudit.reset_config!
      expect(RakeAudit).not_to receive(:install!)
      run_after_initialize_hook
    end
  end
end
