# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-06-04

### Added

- Example Rails app in `examples/dummy_app/` demonstrating full setup with SQLite and five demo Rake tasks.

## [0.1.0] - 2026-06-03

Initial public release.

### Added

- **Automatic Rake auditing** — a prepended `Rake::Task#execute` hook records the
  task name, arguments, start/finish times, duration, status (success/failure), and
  error details for every Rake task execution, without altering task behavior.
- **Pluggable storage adapters** built on a common `RakeAudit::Adapters::Base`:
  - `ActiveRecordAdapter` — persists executions to a `rake_task_executions` table.
  - `RedisAdapter` — stores executions as JSON in the `rake_audit:executions` list.
  - `MongoAdapter` — stores executions in the `rake_task_executions` collection.
  - Custom adapters are supported by subclassing `Base` and implementing `#save`.
- **Configurable capture** of hostname, PID, Ruby version, and Rails environment,
  plus a configurable logger for adapter save failures.
- **Rails Web UI** (mountable engine) providing:
  - A paginated, filterable execution list (Kaminari-backed).
  - A dashboard with aggregate stats (totals, success/failure counts, average
    duration, top failed tasks).
  - A per-execution detail view.
  - Optional access control via a configurable `authenticate_with` lambda.
- **Rails install generator** (`rails generate rake_audit:install`) that copies an
  initializer and a timestamped ActiveRecord migration.
- **Rails-free operation** — the gem loads and records outside Rails; Kaminari's
  ActiveRecord/ActionView integrations stay inert until those libraries are present.

[Unreleased]: https://github.com/eraxel-dev/rake_audit/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/eraxel-dev/rake_audit/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/eraxel-dev/rake_audit/releases/tag/v0.1.0
