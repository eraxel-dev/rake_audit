# Rake Audit

**Full Audit Trail for Every Rake Execution**

RakeAudit automatically records who ran what, when it started, when it finished, how long it took, and whether it succeeded or failed.

Built for modern Rails applications, it supports pluggable storage adapters including ActiveRecord, Redis, MongoDB, and custom backends.

Gain a complete historical record of your operational tasks without touching your existing codebase.

## Table of Contents

- [Installation](#installation)
- [Setup](#setup)
  - [Rails (ActiveRecord)](#rails-activerecord)
  - [Redis](#redis)
  - [MongoDB](#mongodb)
  - [Plain Ruby / Standalone Rake](#plain-ruby--standalone-rake)
- [Configuration](#configuration)
- [Web UI](#web-ui)
- [Custom Adapter](#custom-adapter)
- [Example Usages](#example-usages)
- [Try the Example App](#try-the-example-app)

---

## Installation

Add the gem to your `Gemfile`:

```ruby
gem 'rake_audit'
```

Then run:

```sh
bundle install
```

Or install directly:

```sh
gem install rake_audit
```

---

## Setup

### Rails (ActiveRecord)

Run the install generator to create the initializer and database migration:

```sh
rails generate rake_audit:install
```

This copies `config/initializers/rake_audit.rb` and a timestamped migration to `db/migrate/`. Run the migration:

```sh
rails db:migrate
```

Then enable the ActiveRecord adapter in `config/initializers/rake_audit.rb`:

```ruby
RakeAudit.configure do |config|
  config.adapter = RakeAudit::Adapters::ActiveRecordAdapter.new
end
```

### Redis

Provide a connected `Redis` client:

```ruby
require 'redis'

RakeAudit.configure do |config|
  config.adapter = RakeAudit::Adapters::RedisAdapter.new(
    client: Redis.new(url: ENV['REDIS_URL'])
  )
end
```

Execution records are stored as JSON in the `rake_audit:executions` list key.

### MongoDB

Provide a connected `Mongo::Client`:

```ruby
require 'mongo'

RakeAudit.configure do |config|
  config.adapter = RakeAudit::Adapters::MongoAdapter.new(
    client: Mongo::Client.new(ENV['MONGODB_URI'])
  )
end
```

Records are stored in the `rake_task_executions` collection.

### Plain Ruby / Standalone Rake

RakeAudit works outside Rails. Require the gem and configure an adapter before tasks run:

```ruby
require 'rake_audit'

RakeAudit.configure do |config|
  config.adapter = MyCustomAdapter.new
end

RakeAudit.install!
```

---

## Configuration

All options with their defaults:

```ruby
RakeAudit.configure do |config|
  # Storage adapter — required to enable recording.
  config.adapter = RakeAudit::Adapters::ActiveRecordAdapter.new

  # Logger for adapter save failures (defaults to Rails.logger or $stdout).
  config.logger = Rails.logger

  # Fields captured on each execution record.
  config.capture_hostname     = true   # machine hostname
  config.capture_pid          = true   # process ID
  config.capture_ruby_version = true   # Ruby version string
  config.capture_rails_env    = true   # Rails.env value

  # Web UI (see below).
  config.web_ui_enabled    = true
  config.authenticate_with = ->(controller) { controller.authenticate_admin! }
end
```

Without an adapter, RakeAudit loads silently and records nothing.

---

## Web UI

Mount the engine in `config/routes.rb` to enable the built-in dashboard and execution list:

```ruby
Rails.application.routes.draw do
  mount RakeAudit::Engine, at: '/rake_audit'
end
```

| Path | Description |
|---|---|
| `/rake_audit` | Paginated execution list with filters |
| `/rake_audit/dashboard` | Aggregate stats (total, success/failure counts, avg duration) |
| `/rake_audit/executions/:id` | Detail view for a single execution |

To restrict access, set `authenticate_with` to a lambda that calls your authentication helper:

```ruby
config.authenticate_with = ->(controller) { controller.authenticate_admin! }
```

---

## Custom Adapter

Subclass `RakeAudit::Adapters::Base` and implement `#save`. Implement the remaining query methods to support the Web UI:

```ruby
class MyAdapter < RakeAudit::Adapters::Base
  def save(record)
    # record is a RakeAudit::TaskExecutionRecord
    # record.to_h returns a plain hash of all fields
    MyStore.insert(record.to_h)
  end

  # Optional — required only when using the Web UI.
  def query(filters: {}, page: nil, per_page: 25) = raise NotImplementedError
  def find(id)                                     = raise NotImplementedError
  def count                                        = raise NotImplementedError
  def count_by_status(status)                      = raise NotImplementedError
  def average_duration_ms                          = raise NotImplementedError
  def top_failed_tasks(limit: 10)                  = raise NotImplementedError
end

RakeAudit.configure { |c| c.adapter = MyAdapter.new }
```

---

## Example Usages

**Query executions directly (ActiveRecord adapter)**

```ruby
# All executions for a task, newest first.
RakeAudit::TaskExecution.where(task_name: 'db:migrate').order(started_at: :desc)

# Failed executions in the last 24 hours.
RakeAudit::TaskExecution.where(status: 'failure')
                        .where(started_at: 24.hours.ago..)
```

**Check stats programmatically**

```ruby
adapter = RakeAudit.config.adapter
stats   = adapter.stats
# => { total: 1482, success_count: 1470, failure_count: 12,
#      average_duration_ms: 843.2, top_failed_tasks: [["db:seed", 7], ...] }
```

**Reset configuration in tests**

```ruby
RSpec.configure do |config|
  config.after { RakeAudit.reset_config! }
end
```

**Disable the Web UI for API-only apps**

```ruby
RakeAudit.configure do |config|
  config.adapter        = RakeAudit::Adapters::ActiveRecordAdapter.new
  config.web_ui_enabled = false
end
```

---

## Try the Example App

A complete, runnable Rails 7 example lives in
[`examples/dummy_app/`](examples/dummy_app/). It wires `rake_audit` into a real
app via a local path gem (`gem 'rake_audit', path: '../..'`), uses SQLite, and
ships five demo Rake tasks plus the mounted Web UI.

```sh
cd examples/dummy_app
bundle install
bin/rails db:setup
bin/rails demo:hello        # records a success
bin/rails demo:flaky        # records a failure
bin/rails server            # then open http://localhost:3000/rake_audit
```

See [`examples/dummy_app/README.md`](examples/dummy_app/README.md) for the full
walkthrough. (The example is not included in the published gem.)
