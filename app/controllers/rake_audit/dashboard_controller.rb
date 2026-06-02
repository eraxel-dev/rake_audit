# frozen_string_literal: true

module RakeAudit
  # Renders the dashboard: six aggregate metrics plus the ten task names with
  # the most failures. All data access is delegated to +web_adapter+ so the
  # controller is backend-agnostic (ActiveRecord, Redis, Mongo, …).
  class DashboardController < ApplicationController
    # Compute the dashboard aggregates and expose them as instance variables.
    # All five metrics are fetched via a single +web_adapter.stats+ call so
    # adapters can compute them in one pass (e.g. one Redis LRANGE instead of five).
    #
    # @return [void]
    def index
      s = web_adapter.stats
      @total               = s[:total]
      @success_count       = s[:success_count]
      @failure_count       = s[:failure_count]
      @failure_rate        = failure_rate(@failure_count, @total)
      @average_duration_ms = s[:average_duration_ms]
      @top_failed_tasks    = s[:top_failed_tasks]
    end

    private

    # Percentage of executions that failed, guarding against division by zero.
    #
    # @param failures [Integer]
    # @param total [Integer]
    # @return [Float]
    def failure_rate(failures, total)
      return 0.0 if total.zero?

      failures / total.to_f * 100
    end
  end
end
