# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'

module RakeAudit
  module Generators
    # Scaffolds RakeAudit into a host Rails application.
    #
    #   rails generate rake_audit:install
    #
    # Running the generator copies a commented-out initializer to
    # +config/initializers/rake_audit.rb+ and writes a timestamped migration to
    # +db/migrate+ that creates the +rake_task_executions+ table. The migration
    # is produced through +migration_template+ so the host's schema version and
    # migration numbering are respected.
    class InstallGenerator < ::Rails::Generators::Base
      include ::ActiveRecord::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      desc 'Creates the RakeAudit initializer and the rake_task_executions migration.'

      # Copy the pre-filled, fully commented initializer into the host app.
      #
      # @return [void]
      def create_initializer
        template 'initializer.rb', 'config/initializers/rake_audit.rb'
      end

      # Generate the timestamped migration that creates the audit table.
      #
      # @return [void]
      def create_migration_file
        migration_template(
          'create_rake_task_executions.rb',
          'db/migrate/create_rake_task_executions.rb'
        )
      end
    end
  end
end
