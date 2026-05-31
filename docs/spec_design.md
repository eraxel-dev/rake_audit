# RakeAudit Implementation-Ready Detailed Design Document

Version: 1.0
Target: Ruby 3.2+, Rails 7/8, Rake 13+

---

# 1. Purpose

Collect, store, and visualize the execution history of Rake tasks.

Requirements:

- No changes to Rake task code required
- Does not alter Rake task behavior
- Does not change exception propagation
- Supports ActiveRecord / Redis / Mongo / Custom Storage
- Provides a Web UI as a Rails Engine
- Provides a Migration Generator

---

# 2. Non-Functional Requirements

## Performance

Additional overhead:

- Capture start time
- Capture end time
- Build DTO
- Save via Adapter

Target:

- Within 1ms–5ms

## Availability

Storage failure must not affect task success or failure.

---

# 3. Architecture

Rake::Task
  ↓
TaskPatch
  ↓
ExecutionRecorder
  ↓
TaskExecutionRecord
  ↓
Adapter
  ├─ ActiveRecordAdapter
  ├─ RedisAdapter
  ├─ MongoAdapter
  └─ CustomAdapter

---

# 4. Directory Structure

lib/rake_audit/
  configuration.rb
  execution_recorder.rb
  task_patch.rb
  version.rb

  adapters/
    base.rb
    active_record_adapter.rb
    redis_adapter.rb
    mongo_adapter.rb

  builders/
    task_execution_record_builder.rb

  rails/
    engine.rb
    railtie.rb

app/
  models/
    rake_audit/task_execution.rb

  controllers/
    rake_audit/
      executions_controller.rb
      dashboard_controller.rb

  views/

db/migrate/

lib/generators/
  rake_audit/install_generator.rb

---

# 5. Configuration

class Configuration

Attributes:

adapter
logger

capture_hostname
capture_pid
capture_ruby_version
capture_rails_env

web_ui_enabled

end

Defaults:

adapter=nil
logger=Rails.logger

---

# 6. DTO

TaskExecutionRecord

Attributes:

task_name:String
arguments:Hash

started_at:Time
finished_at:Time

duration_ms:Integer

status:String

error_class:String?
error_message:String?

hostname:String?
pid:Integer?
ruby_version:String?
rails_env:String?

---

# 7. Hook Strategy

## Adopted

Rake::Task#execute

Reasons:

- Records only tasks that were actually executed
- Less affected by invoke/reenable
- Dependency tasks can also be captured

Implementation:

module TaskPatch
  def execute(args=nil)
    ExecutionRecorder.new(
      task: self,
      args: args
    ).record { super }
  end
end

---

# 8. ExecutionRecorder

Responsibilities:

- Start timer
- Execute
- Capture exception
- Build DTO
- Save via Adapter

Exception handling:

rescue Exception => e
  raise
ensure
  save_record
end

---

# 9. Record Builder

TaskExecutionRecordBuilder

Input:

task
args
execution_result

Output:

TaskExecutionRecord

Collects:

Socket.gethostname
Process.pid
RUBY_VERSION
Rails.env

---

# 10. Adapter API

class Base
  def save(record)
    raise NotImplementedError
  end
end

Rules:

- save is synchronous
- Return value not required
- May raise exceptions

---

# 11. ActiveRecord Adapter

class ActiveRecordAdapter

Saves to:

RakeAudit::TaskExecution

end

create!(record.to_h)

---

# 12. Redis Adapter

Key:

rake_audit:executions

Save:

LPUSH

Value:

JSON

---

# 13. Mongo Adapter

collection:

rake_task_executions

insert_one(record.to_h)

---

# 14. Rails Model

table:

rake_task_executions

Validation:

task_name presence
status presence
started_at presence
finished_at presence

---

# 15. DB Design

Table:

rake_task_executions

Columns:

id bigint PK

task_name string(255)

arguments jsonb

started_at datetime
finished_at datetime

duration_ms bigint

status string(20)

error_class string(255)
error_message text

hostname string(255)

pid integer

ruby_version string(50)

rails_env string(50)

created_at
updated_at

---

# 16. Index Design

index task_name

index status

index started_at

index hostname

Composite:

index(task_name, started_at)

index(status, started_at)

---

# 17. Generator

rails generate rake_audit:install

Generates:

initializer
migration

---

# 18. Rails Engine

class Engine < Rails::Engine

isolate_namespace RakeAudit

end

---

# 19. Route Design

/rake_audit

/rake_audit/dashboard

/rake_audit/executions

/rake_audit/executions/:id

---

# 20. Dashboard Page

Displays:

Total executions

Success count

Failure count

Failure rate

Average execution time

Top 10 failed tasks

---

# 21. List Page

Columns:

Task Name

Status

Duration

Started At

Hostname

Rails Env

Filters:

task_name

status

hostname

rails_env

date range

---

# 22. Detail Page

Task information

Arguments

Execution information

Error information

Environment information

---

# 23. Authorization

Configuration:

authenticate_with block

Example:

RakeAudit.configure do |c|
  c.authenticate_with = ->(controller) {
    controller.authenticate_admin!
  }
end

---

# 24. Logging Policy

On save failure:

Output only:

[RakeAudit] Save failed

---

# 25. Test Strategy

Unit

- Configuration
- Builder
- Adapter

Integration

- execute hook
- successful task
- failed task

System

- Dashboard
- List
- Detail

---

# 26. Compatibility

Ruby

3.2
3.3
3.4

Rails

7.0
7.1
8.0

DB

PostgreSQL
MySQL
SQLite

---

# 27. Future Extensions

git_sha

host_ip

container_id

request_id

queue_name

tags(jsonb)

metadata(jsonb)

---

# 28. Release Plan

v1.0

- Hook
- ActiveRecord
- Redis
- UI


v1.1

- Metrics API


v1.2

- Mongo
- Async Adapter
- OpenTelemetry Integration
