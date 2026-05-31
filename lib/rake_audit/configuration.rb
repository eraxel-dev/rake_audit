# frozen_string_literal: true

require 'logger'

module RakeAudit
  # Holds all tunable settings for RakeAudit.
  #
  # An instance is created lazily by {RakeAudit.config} and mutated through
  # {RakeAudit.configure}. All attributes carry sane defaults so that the gem
  # is safe to load even when nothing has been configured.
  class Configuration
    # @return [Object, nil] storage adapter instance responding to +#save(record)+.
    #   When +nil+, recording is a no-op.
    attr_accessor :adapter

    # @return [Logger] logger used to report adapter save failures.
    attr_accessor :logger

    # @return [Boolean] whether to capture the machine hostname.
    attr_accessor :capture_hostname

    # @return [Boolean] whether to capture the process id.
    attr_accessor :capture_pid

    # @return [Boolean] whether to capture the Ruby version.
    attr_accessor :capture_ruby_version

    # @return [Boolean] whether to capture the Rails environment.
    attr_accessor :capture_rails_env

    # @return [Boolean] whether the bundled Web UI is enabled.
    attr_accessor :web_ui_enabled

    # @return [Proc, nil] callable used to authenticate Web UI requests.
    attr_accessor :authenticate_with

    def initialize
      @adapter = nil
      @logger = default_logger
      @capture_hostname = true
      @capture_pid = true
      @capture_ruby_version = true
      @capture_rails_env = true
      @web_ui_enabled = true
      @authenticate_with = nil
    end

    private

    # Prefer +Rails.logger+ when running inside a Rails app, otherwise fall back
    # to a plain stdout logger so the gem works standalone.
    #
    # @return [Logger]
    def default_logger
      if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
        Rails.logger
      else
        Logger.new($stdout)
      end
    end
  end
end
