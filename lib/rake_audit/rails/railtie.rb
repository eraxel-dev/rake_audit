# frozen_string_literal: true

module RakeAudit
  # Hooks RakeAudit into the Rails boot process.
  #
  # The {RakeAudit::TaskPatch} is prepended into +Rake::Task+ only after the
  # full Rails application has initialized, and only when a storage adapter has
  # been configured. Deferring to +after_initialize+ guarantees that the
  # initializer (e.g. +config/initializers/rake_audit.rb+) has already run and
  # that every dependency the adapter needs is loaded; skipping the prepend when
  # no adapter is present keeps recording a true no-op for unconfigured apps.
  class Railtie < ::Rails::Railtie
    config.after_initialize do
      RakeAudit.install! if RakeAudit.config.adapter
    end
  end
end
