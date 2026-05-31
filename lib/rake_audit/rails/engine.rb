# frozen_string_literal: true

module RakeAudit
  # Rails Engine for RakeAudit.
  #
  # Mounting an isolated Engine namespaces the gem's models, controllers, and
  # routes under +RakeAudit+ so they never collide with the host application.
  # The Engine also makes the gem's +app/+ directory part of the host app's
  # load paths, which is how {RakeAudit::TaskExecution} becomes autoloadable.
  class Engine < ::Rails::Engine
    isolate_namespace RakeAudit
  end
end
