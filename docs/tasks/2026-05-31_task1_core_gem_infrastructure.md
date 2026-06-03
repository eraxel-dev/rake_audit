# Task 1 — Core Gem Infrastructure

## Goal

Build the foundational gem skeleton and recording pipeline that intercepts Rake task execution and captures execution data without altering task behavior.

## Files to Create

| File | Purpose |
|---|---|
| `rake_audit.gemspec` | Gem specification (dependencies: rake, optional: activerecord, redis, mongo) |
| `lib/rake_audit.rb` | Entry point; requires all components; exposes `RakeAudit.configure` block |
| `lib/rake_audit/version.rb` | `VERSION = "0.1.0"` |
| `lib/rake_audit/configuration.rb` | Configuration class with all attributes and defaults |
| `lib/rake_audit/task_execution_record.rb` | Struct-based DTO holding all 12 execution fields |
| `lib/rake_audit/builders/task_execution_record_builder.rb` | Builds a `TaskExecutionRecord` from task/args/execution result |
| `lib/rake_audit/execution_recorder.rb` | Wraps task execution; records timing, status, exception |
| `lib/rake_audit/task_patch.rb` | Prepends into `Rake::Task` to intercept `#execute` |

## Configuration Attributes

```ruby
class Configuration
  attr_accessor :adapter          # Storage adapter instance (default: nil)
  attr_accessor :logger           # Logger (default: Rails.logger or Logger.new($stdout))
  attr_accessor :capture_hostname # (default: true)
  attr_accessor :capture_pid      # (default: true)
  attr_accessor :capture_ruby_version # (default: true)
  attr_accessor :capture_rails_env    # (default: true)
  attr_accessor :web_ui_enabled   # (default: true)
  attr_accessor :authenticate_with # Proc for Web UI auth (default: nil)
end
```

## TaskExecutionRecord Fields

```
task_name:      String
arguments:      Hash
started_at:     Time
finished_at:    Time
duration_ms:    Integer
status:         String   # "success" or "failure"
error_class:    String?
error_message:  String?
hostname:       String?
pid:            Integer?
ruby_version:   String?
rails_env:      String?
```

## TaskPatch Implementation

```ruby
module TaskPatch
  def execute(args = nil)
    ExecutionRecorder.new(task: self, args: args).record { super }
  end
end

Rake::Task.prepend(TaskPatch)
```

## ExecutionRecorder Logic

```ruby
def record
  started_at = Time.now
  exception = nil
  begin
    yield
  rescue Exception => e
    exception = e
    raise
  ensure
    save_record(started_at: started_at, exception: exception)
  end
end

def save_record(...)
  record = TaskExecutionRecordBuilder.build(...)
  RakeAudit.config.adapter.save(record)
rescue => e
  RakeAudit.config.logger.error("[RakeAudit] Save failed: #{e.message}")
end
```

## Key Invariants

- **Re-raise**: The original task exception must propagate unchanged.
- **Silence adapter errors**: Adapter failures are logged only — never allowed to affect the task result.
- **No-op when adapter is nil**: Skip saving entirely if no adapter is configured.
- **`to_h`** on `TaskExecutionRecord` is the serialization boundary used by all adapters.

## Acceptance Criteria

- [ ] `RakeAudit.configure { |c| c.adapter = ... }` works
- [ ] `Rake::Task#execute` is intercepted via prepend
- [ ] Successful task produces record with `status: "success"`
- [ ] Failed task produces record with `status: "failure"`, `error_class`, `error_message`, and re-raises the original exception
- [ ] Adapter error does not propagate; a log line is emitted instead
- [ ] `to_h` returns a plain Hash with all 12 fields
