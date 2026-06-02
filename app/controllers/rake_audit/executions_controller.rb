# frozen_string_literal: true

module RakeAudit
  # Lists recorded task executions (with filtering + pagination) and shows the
  # detail of a single execution.
  class ExecutionsController < ApplicationController
    # Exact-match filters: request param name => column queried.
    EXACT_FILTERS = {
      task_name: :task_name,
      status: :status,
      hostname: :hostname,
      rails_env: :rails_env
    }.freeze

    # Newest-first, filtered, paginated list of executions.
    #
    # @return [void]
    def index
      scope = TaskExecution.order(started_at: :desc)
      scope = apply_exact_filters(scope)
      scope = apply_date_range(scope)
      @executions = scope.page(params[:page])
    end

    # Detail of one execution, looked up by id.
    #
    # @return [void]
    def show
      @execution = TaskExecution.find(params[:id])
    end

    private

    # Apply every present exact-match filter from {EXACT_FILTERS} to the scope.
    #
    # @param scope [ActiveRecord::Relation]
    # @return [ActiveRecord::Relation]
    def apply_exact_filters(scope)
      EXACT_FILTERS.reduce(scope) do |relation, (param, column)|
        value = params[param]
        value.present? ? relation.where(column => value) : relation
      end
    end

    # Apply the inclusive +from+/+to+ +started_at+ bounds when present.
    #
    # @param scope [ActiveRecord::Relation]
    # @return [ActiveRecord::Relation]
    def apply_date_range(scope)
      scope = scope.where(started_at: params[:from]..) if params[:from].present?
      scope = scope.where(started_at: ..params[:to]) if params[:to].present?
      scope
    end
  end
end
