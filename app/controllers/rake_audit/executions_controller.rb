# frozen_string_literal: true

module RakeAudit
  # Lists recorded task executions (with filtering + pagination) and shows the
  # detail of a single execution. All data access is delegated to +web_adapter+
  # so the controller is backend-agnostic (ActiveRecord, Redis, Mongo, …).
  class ExecutionsController < ApplicationController
    # Newest-first, filtered, paginated list of executions.
    #
    # @return [void]
    def index
      @executions = web_adapter.query(filters: filter_params, page: params[:page])
    end

    # Detail of one execution, looked up by id.
    #
    # @return [void]
    def show
      @execution = web_adapter.find(params[:id])
    end

    private

    # Build a filter hash from request params, omitting any blank values so
    # adapters can safely check +filters.key?(col)+ without blank-value guards.
    #
    # @return [Hash]
    def filter_params
      {
        task_name: params[:task_name],
        status: params[:status],
        hostname: params[:hostname],
        rails_env: params[:rails_env],
        from: params[:from],
        to: params[:to]
      }.reject { |_, v| v.blank? }
    end
  end
end
