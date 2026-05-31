# frozen_string_literal: true

RSpec.describe RakeAudit::Configuration do
  subject(:config) { described_class.new }

  describe 'defaults' do
    it 'defaults adapter to nil' do
      expect(config.adapter).to be_nil
    end

    it 'provides a logger' do
      expect(config.logger).to respond_to(:error)
    end

    it 'enables all capture flags by default' do
      expect(config.capture_hostname).to be(true)
      expect(config.capture_pid).to be(true)
      expect(config.capture_ruby_version).to be(true)
      expect(config.capture_rails_env).to be(true)
    end

    it 'enables the web UI by default' do
      expect(config.web_ui_enabled).to be(true)
    end

    it 'defaults authenticate_with to nil' do
      expect(config.authenticate_with).to be_nil
    end
  end

  describe 'mutability' do
    it 'allows overriding every attribute' do
      adapter = Object.new
      logger = Logger.new(nil)
      auth = ->(_c) { true }

      config.adapter = adapter
      config.logger = logger
      config.capture_hostname = false
      config.capture_pid = false
      config.capture_ruby_version = false
      config.capture_rails_env = false
      config.web_ui_enabled = false
      config.authenticate_with = auth

      expect(config.adapter).to be(adapter)
      expect(config.logger).to be(logger)
      expect(config.capture_hostname).to be(false)
      expect(config.capture_pid).to be(false)
      expect(config.capture_ruby_version).to be(false)
      expect(config.capture_rails_env).to be(false)
      expect(config.web_ui_enabled).to be(false)
      expect(config.authenticate_with).to be(auth)
    end
  end
end

RSpec.describe RakeAudit do
  describe '.configure' do
    it 'yields the configuration for mutation' do
      adapter = Object.new
      RakeAudit.configure { |c| c.adapter = adapter }
      expect(RakeAudit.config.adapter).to be(adapter)
    end

    it 'returns the configuration' do
      # rubocop:disable Lint/EmptyBlock
      expect(RakeAudit.configure { |_c| }).to be(RakeAudit.config)
      # rubocop:enable Lint/EmptyBlock
    end

    it 'memoizes the configuration across calls' do
      first = RakeAudit.config
      expect(RakeAudit.config).to be(first)
    end
  end
end
