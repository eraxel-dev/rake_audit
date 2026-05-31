# Task 4 — Web UI (Routes, Controllers & Views)

## Goal

Deliver the browser interface mounted at `/rake_audit`: a dashboard with aggregate stats, a paginated and filterable execution list, and a detail page. Includes pluggable authentication.

## Dependency

Requires Task 3 (Rails Engine, DB Layer & Generator) — controllers query `RakeAudit::TaskExecution`.

## Files to Create

| File | Purpose |
|---|---|
| `config/routes.rb` (Engine) | 4 routes under the Engine's namespace |
| `app/controllers/rake_audit/application_controller.rb` | Base controller with auth hook |
| `app/controllers/rake_audit/executions_controller.rb` | List (index) and detail (show) |
| `app/controllers/rake_audit/dashboard_controller.rb` | Aggregate stats |
| `app/views/layouts/rake_audit/application.html.erb` | Minimal shared layout |
| `app/views/rake_audit/dashboard/index.html.erb` | Dashboard page |
| `app/views/rake_audit/executions/index.html.erb` | Execution list page |
| `app/views/rake_audit/executions/show.html.erb` | Execution detail page |

## Routes

```ruby
RakeAudit::Engine.routes.draw do
  root to: "executions#index"
  get  "dashboard", to: "dashboard#index"
  resources :executions, only: [:index, :show]
end
```

Mounted in host app:
```ruby
mount RakeAudit::Engine => "/rake_audit"
```

Final URL map:

| URL | Action |
|---|---|
| `GET /rake_audit` | `executions#index` |
| `GET /rake_audit/dashboard` | `dashboard#index` |
| `GET /rake_audit/executions` | `executions#index` |
| `GET /rake_audit/executions/:id` | `executions#show` |

## ApplicationController

```ruby
module RakeAudit
  class ApplicationController < ActionController::Base
    before_action :authenticate!

    private

    def authenticate!
      return unless RakeAudit.config.authenticate_with
      instance_exec(self, &RakeAudit.config.authenticate_with)
    end
  end
end
```

## ExecutionsController

```ruby
module RakeAudit
  class ExecutionsController < ApplicationController
    def index
      @executions = TaskExecution.order(started_at: :desc)
      @executions = @executions.where(task_name: params[:task_name])  if params[:task_name].present?
      @executions = @executions.where(status: params[:status])        if params[:status].present?
      @executions = @executions.where(hostname: params[:hostname])    if params[:hostname].present?
      @executions = @executions.where(rails_env: params[:rails_env])  if params[:rails_env].present?
      @executions = @executions.where("started_at >= ?", params[:from]) if params[:from].present?
      @executions = @executions.where("started_at <= ?", params[:to])   if params[:to].present?
      @executions = @executions.page(params[:page])
    end

    def show
      @execution = TaskExecution.find(params[:id])
    end
  end
end
```

## DashboardController

Aggregates computed from `TaskExecution`:

| Metric | Query |
|---|---|
| Total executions | `count` |
| Success count | `where(status: "success").count` |
| Failure count | `where(status: "failure").count` |
| Failure rate | `failure_count / total.to_f * 100` |
| Average duration (ms) | `average(:duration_ms)` |
| Top 10 failed tasks | `where(status: "failure").group(:task_name).count.sort_by { -_2 }.first(10)` |

## Dashboard Page

Sections:
- **Stat cards**: Total, Success, Failure, Failure Rate %, Avg Duration
- **Top 10 failed tasks** table: Task Name | Failure Count

## Execution List Page

Filter form fields: `task_name` (text), `status` (select: all/success/failure), `hostname` (text), `rails_env` (text), `from` date, `to` date.

Table columns: Task Name | Status | Duration (ms) | Started At | Hostname | Rails Env | (link to detail)

## Execution Detail Page

Sections:

1. **Task Info** — task_name, status
2. **Arguments** — formatted JSON
3. **Execution Info** — started_at, finished_at, duration_ms
4. **Error Info** — error_class, error_message (hidden when status is success)
5. **Environment Info** — hostname, pid, ruby_version, rails_env

## Authentication

Configure in initializer:

```ruby
RakeAudit.configure do |config|
  config.authenticate_with = ->(controller) {
    controller.authenticate_admin!
  }
end
```

When `authenticate_with` is `nil`, all pages are publicly accessible.

## Acceptance Criteria

- [ ] All 4 routes resolve correctly when Engine is mounted
- [ ] Dashboard displays all 6 metrics
- [ ] Top-10 failed tasks table is ordered by failure count descending
- [ ] Execution list filters by each of: task_name, status, hostname, rails_env, date range
- [ ] Execution list is paginated and ordered by `started_at DESC`
- [ ] Detail page shows all 5 sections; Error Info section is hidden for successful executions
- [ ] `authenticate_with` block is called as `before_action`; no-op when nil
