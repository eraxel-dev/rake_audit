# frozen_string_literal: true

# Kaminari powers the execution list's pagination (+.page+ in the controller and
# the +paginate+ helper in the view). Requiring it alongside the Engine — which
# is itself only loaded when Rails is present — guarantees Kaminari's
# ActiveRecord and ActionView integrations are active for the Web UI without
# forcing the dependency on a plain-Ruby (no Rails) load of the gem.
require 'kaminari'

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
