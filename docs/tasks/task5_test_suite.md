# Task 5 — Test Suite

## Goal

Provide full automated coverage across unit, integration, and system layers. Tests verify both the happy path and the failure cases that define the gem's safety contract.

## Dependency

Requires Tasks 1–4 (all implementation tasks complete).

## Test Framework

- RSpec (`rspec-rails`)
- Capybara for system tests
- FactoryBot for fixtures
- Database Cleaner for test isolation

## Files to Create

### Unit Tests

| File | What It Tests |
|---|---|
| `spec/rake_audit/configuration_spec.rb` | Attribute defaults, custom assignment, `configure` block |
| `spec/rake_audit/task_execution_record_spec.rb` | DTO construction, `to_h` output shape |
| `spec/rake_audit/builders/task_execution_record_builder_spec.rb` | Field population from task/args/result; conditional capture flags |
| `spec/rake_audit/execution_recorder_spec.rb` | Timer, success/failure status, exception re-raise, adapter error silencing |
| `spec/rake_audit/adapters/base_spec.rb` | `NotImplementedError` on `save` |
| `spec/rake_audit/adapters/active_record_adapter_spec.rb` | Delegates to `TaskExecution.create!` with `record.to_h` |
| `spec/rake_audit/adapters/redis_adapter_spec.rb` | LPUSH with JSON to key `rake_audit:executions` |
| `spec/rake_audit/adapters/mongo_adapter_spec.rb` | `insert_one` on collection `rake_task_executions` |

### Integration Tests

| File | What It Tests |
|---|---|
| `spec/integration/execute_hook_spec.rb` | End-to-end: real Rake task + adapter stub |

Key scenarios for `execute_hook_spec.rb`:
- Successful task → record saved with `status: "success"`, correct `duration_ms`, no error fields
- Failing task → record saved with `status: "failure"`, `error_class`, `error_message` populated, original exception re-raised to caller
- Adapter error during save → task result unaffected, error is logged, no exception propagates

### System Tests

| File | What It Tests |
|---|---|
| `spec/system/dashboard_spec.rb` | Dashboard page renders all 6 metrics |
| `spec/system/executions_index_spec.rb` | List page: columns, filter form, pagination |
| `spec/system/executions_show_spec.rb` | Detail page: all 5 sections, Error Info hidden for success |

## Key Test Cases

### ExecutionRecorder (unit)

```ruby
it "re-raises the original exception" do
  allow(adapter).to receive(:save)
  expect { recorder.record { raise RuntimeError, "boom" } }.to raise_error(RuntimeError, "boom")
end

it "saves record even when task raises" do
  allow(adapter).to receive(:save)
  recorder.record { raise "boom" } rescue nil
  expect(adapter).to have_received(:save)
end

it "does not propagate adapter errors" do
  allow(adapter).to receive(:save).and_raise("storage down")
  expect { recorder.record { } }.not_to raise_error
end
```

### Execute Hook (integration)

```ruby
it "records a successful task" do
  records = []
  stub_adapter = ->(rec) { records << rec }
  # configure adapter, define and invoke rake task
  expect(records.first.status).to eq("success")
  expect(records.first.task_name).to eq("test:task")
end
```

### Dashboard (system)

```ruby
it "displays total execution count" do
  create_list(:task_execution, 3)
  visit rake_audit.dashboard_path
  expect(page).to have_content("3")
end
```

## Spec Helper Setup

```ruby
# spec/spec_helper.rb
require "rake_audit"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
end
```

## Acceptance Criteria

- [ ] All unit specs pass without a database or external services
- [ ] `ExecutionRecorder` specs cover: success, failure, adapter error silencing, timer accuracy
- [ ] Builder specs verify all 12 fields are populated; capture flags suppress optional fields when false
- [ ] Integration spec covers: success record, failure record + re-raise, adapter error silencing
- [ ] System specs cover: dashboard metrics, list filters, detail sections, error section visibility
- [ ] `rspec spec/` runs green with zero failures
