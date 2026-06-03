# Task 3 — Rails Engine, DB Layer & Install Generator

## Goal

Wire up Rails integration: the Engine, Railtie, the `TaskExecution` ActiveRecord model, the database migration, and the install generator that scaffolds both into a host application.

## Dependency

Requires Task 2 (Storage Adapters) — `ActiveRecordAdapter` depends on the `TaskExecution` model.

## Files to Create

| File | Purpose |
|---|---|
| `lib/rake_audit/rails/engine.rb` | Mounts RakeAudit as an isolated Rails Engine |
| `lib/rake_audit/rails/railtie.rb` | Hooks TaskPatch into Rails initialization |
| `app/models/rake_audit/task_execution.rb` | ActiveRecord model with validations |
| `db/migrate/YYYYMMDDHHMMSS_create_rake_task_executions.rb` | Database migration |
| `lib/generators/rake_audit/install_generator.rb` | `rails generate rake_audit:install` |
| `lib/generators/rake_audit/templates/initializer.rb` | Initializer template copied to host app |

## Rails Engine

```ruby
module RakeAudit
  class Engine < Rails::Engine
    isolate_namespace RakeAudit
  end
end
```

## Railtie

```ruby
module RakeAudit
  class Railtie < Rails::Railtie
    config.after_initialize do
      if RakeAudit.config.adapter
        Rake::Task.prepend(RakeAudit::TaskPatch)
      end
    end
  end
end
```

- Only prepends `TaskPatch` when an adapter is configured
- Runs after full Rails initialization so all dependencies are available

## TaskExecution Model

```ruby
module RakeAudit
  class TaskExecution < ApplicationRecord
    self.table_name = "rake_task_executions"

    validates :task_name, presence: true
    validates :status,    presence: true
    validates :started_at, presence: true
    validates :finished_at, presence: true
  end
end
```

## DB Migration

Table: `rake_task_executions`

### Columns

| Column | Type | Notes |
|---|---|---|
| `id` | bigint | PK, auto-increment |
| `task_name` | string(255) | not null |
| `arguments` | jsonb | nullable |
| `started_at` | datetime | not null |
| `finished_at` | datetime | not null |
| `duration_ms` | bigint | nullable |
| `status` | string(20) | not null |
| `error_class` | string(255) | nullable |
| `error_message` | text | nullable |
| `hostname` | string(255) | nullable |
| `pid` | integer | nullable |
| `ruby_version` | string(50) | nullable |
| `rails_env` | string(50) | nullable |
| `created_at` | datetime | |
| `updated_at` | datetime | |

### Indexes

| Index | Type |
|---|---|
| `task_name` | single |
| `status` | single |
| `started_at` | single |
| `hostname` | single |
| `(task_name, started_at)` | composite |
| `(status, started_at)` | composite |

## Install Generator

```
rails generate rake_audit:install
```

Generates:
1. `config/initializers/rake_audit.rb` — from template, pre-filled with all config options commented out
2. `db/migrate/YYYYMMDDHHMMSS_create_rake_task_executions.rb` — timestamped migration via `migration_template`

## Initializer Template

```ruby
RakeAudit.configure do |config|
  # config.adapter = RakeAudit::Adapters::ActiveRecordAdapter.new
  # config.logger  = Rails.logger
  # config.capture_hostname    = true
  # config.capture_pid         = true
  # config.capture_ruby_version = true
  # config.capture_rails_env   = true
  # config.web_ui_enabled      = true
  # config.authenticate_with   = ->(controller) { controller.authenticate_admin! }
end
```

## Acceptance Criteria

- [ ] Engine mounts with `isolate_namespace RakeAudit`
- [ ] Railtie prepends `TaskPatch` only when adapter is configured
- [ ] `TaskExecution` validates presence of `task_name`, `status`, `started_at`, `finished_at`
- [ ] Migration creates all columns and all 6 indexes
- [ ] `rails generate rake_audit:install` produces initializer and migration in host app
- [ ] Running generated migration succeeds on PostgreSQL, MySQL, and SQLite
