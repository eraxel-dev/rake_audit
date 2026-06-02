# frozen_string_literal: true

# Routes for the mounted RakeAudit Engine.
#
# Because the Engine isolates its namespace, these paths live beneath the mount
# point the host application chooses (conventionally +/rake_audit+). The root
# points at the execution list so the mount point itself is useful; the
# dashboard and the execution +index+/+show+ actions round out the UI.
RakeAudit::Engine.routes.draw do
  root to: 'executions#index'
  get 'dashboard', to: 'dashboard#index'
  resources :executions, only: %i[index show]
end
