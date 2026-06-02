# frozen_string_literal: true

module RakeAudit
  # Renders the dashboard: six aggregate metrics computed from
  # {RakeAudit::TaskExecution}, plus the ten task names with the most failures.
  class DashboardController < ApplicationController
    # Compute the dashboard aggregates in a single pass of small queries and
    # expose them as instance variables for the view.
    #
    # @return [void]
    def index
      @total = TaskExecution.count
      @success_count = TaskExecution.where(status: 'success').count
      @failure_count = TaskExecution.where(status: 'failure').count
      @failure_rate = failure_rate(@failure_count, @total)
      @average_duration_ms = TaskExecution.average(:duration_ms)
      @top_failed_tasks = top_failed_tasks
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

    # The ten task names with the most failures, ordered by failure count
    # descending. Returned as an Array of +[task_name, count]+ pairs.
    #
    # @return [Array<Array(String, Integer)>]
    def top_failed_tasks
      TaskExecution
        .where(status: 'failure')
        .group(:task_name)
        .count
        .sort_by { |_task_name, count| -count }
        .first(10)
    end
  end
end
