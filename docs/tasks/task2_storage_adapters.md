# Task 2 — Storage Adapters

## Goal

Implement four persistence backends behind a common interface. Adapters are the only component that touches external storage; the rest of the gem is storage-agnostic.

## Dependency

Requires Task 1 (Core Gem Infrastructure) — adapters consume `TaskExecutionRecord` and `to_h`.

## Files to Create

| File | Purpose |
|---|---|
| `lib/rake_audit/adapters/base.rb` | Abstract base; defines the `save(record)` contract |
| `lib/rake_audit/adapters/active_record_adapter.rb` | Persists via `RakeAudit::TaskExecution.create!` |
| `lib/rake_audit/adapters/redis_adapter.rb` | Persists via Redis `LPUSH` as JSON |
| `lib/rake_audit/adapters/mongo_adapter.rb` | Persists via MongoDB `insert_one` |

## Adapter Interface

```ruby
module RakeAudit
  module Adapters
    class Base
      def save(record)
        raise NotImplementedError, "#{self.class}#save is not implemented"
      end
    end
  end
end
```

Rules:
- `save` is **synchronous**
- Return value is **ignored** by callers
- Adapters **may raise** exceptions — `ExecutionRecorder` catches and logs them

## ActiveRecord Adapter

```ruby
class ActiveRecordAdapter < Base
  def save(record)
    RakeAudit::TaskExecution.create!(record.to_h)
  end
end
```

Usage:
```ruby
RakeAudit.configure { |c| c.adapter = RakeAudit::Adapters::ActiveRecordAdapter.new }
```

## Redis Adapter

```ruby
class RedisAdapter < Base
  def initialize(client:)
    @client = client
  end

  def save(record)
    @client.lpush("rake_audit:executions", record.to_h.to_json)
  end
end
```

- Key: `rake_audit:executions`
- Command: `LPUSH`
- Value format: JSON string

Usage:
```ruby
RakeAudit.configure { |c| c.adapter = RakeAudit::Adapters::RedisAdapter.new(client: Redis.new) }
```

## Mongo Adapter

```ruby
class MongoAdapter < Base
  def initialize(client:)
    @client = client
  end

  def save(record)
    collection.insert_one(record.to_h)
  end

  private

  def collection
    @client["rake_task_executions"]
  end
end
```

- Collection: `rake_task_executions`
- Command: `insert_one`

Usage:
```ruby
RakeAudit.configure { |c| c.adapter = RakeAudit::Adapters::MongoAdapter.new(client: Mongo::Client.new(...)) }
```

## Acceptance Criteria

- [ ] `Base#save` raises `NotImplementedError`
- [ ] `ActiveRecordAdapter#save` calls `TaskExecution.create!` with `record.to_h`
- [ ] `RedisAdapter#save` calls `LPUSH "rake_audit:executions" <JSON>`
- [ ] `MongoAdapter#save` calls `insert_one` on collection `rake_task_executions`
- [ ] All adapters inherit from `Base`
- [ ] Each adapter accepts its client dependency via constructor (Redis/Mongo)
