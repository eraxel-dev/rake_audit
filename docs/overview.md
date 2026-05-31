# RakeAudit Detailed Design Document

## Overview

Prepend `Rake::Task#execute` to capture execution events, and separate persistence via the Adapter pattern.
Saves execution history without changing the behavior of Rake tasks.

## Stored Fields

- task_name
- arguments
- started_at
- finished_at
- duration_ms
- status (success/failure)
- error_class
- error_message
- hostname
- pid
- ruby_version
- rails_env

## Architecture

Rake::Task#execute
↓
ExecutionRecorder
↓
TaskExecutionRecord
↓
Adapter
  - ActiveRecord
  - Redis
  - MongoDB
  - Custom

## Gem Structure

lib/
  rake_audit.rb
  configuration.rb
  execution_recorder.rb
  task_patch.rb
  record.rb

  adapters/
    base.rb
    active_record.rb
    redis.rb
    mongo.rb

  rails/
    engine.rb
    railtie.rb

app/
  models/
  controllers/
  views/

generators/

## TaskExecutionRecord

Struct-based DTO

task_name
arguments
started_at
finished_at
duration_ms
status
error_class
error_message
hostname
pid
ruby_version
rails_env

## Task Patch

Prepend `Rake::Task#execute`

Delegate to ExecutionRecorder.

## ExecutionRecorder

- Record start time
- Execute
- Determine success/failure
- Capture exception info
- Save in ensure block
- Re-raise original exception

## Adapter Interface

Only defines:

save(record)

## ActiveRecord Adapter

TaskExecution.create!(record.to_h)

## Migration

create_table :rake_task_executions

Columns:
- task_name
- arguments(jsonb)
- started_at
- finished_at
- duration_ms
- status
- error_class
- error_message
- hostname
- pid
- ruby_version
- rails_env

Index:
- task_name
- status
- started_at
- hostname

## Web UI

mount RakeAudit::Engine => "/rake_audit"

Pages:

### List
/rake_audit

### Detail
/rake_audit/executions/:id

### Dashboard
/rake_audit/dashboard

Displays:
- Total executions
- Success count
- Failure count
- Failure rate

## Key Principles

- Do not change the execution result of Rake tasks
- Do not swallow exceptions
- Log only on save failure
- Do not fail the task due to adapter errors

## Future Extensions

- git_sha
- host_ip
- container_id
- request_id
- queue_name
