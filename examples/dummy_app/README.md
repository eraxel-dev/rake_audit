# rake_audit Example App (`dummy_app`)

A minimal, runnable Rails 7 application that demonstrates [`rake_audit`](../../)
end-to-end: automatic auditing of Rake task runs (success **and** failure), the
ActiveRecord storage adapter, querying recorded executions, and the mounted Web
UI dashboard.

The app consumes the gem from the local checkout via:

```ruby
# Gemfile
gem 'rake_audit', path: '../..'
```

so it always exercises the **current** gem source, not a published release. The
database is **SQLite only**.

> This example lives inside the gem repo for documentation purposes and is
> **not** shipped in the published gem (the gemspec `spec.files` globs do not
> include `examples/`).

---

## 1. Setup

From this directory (`examples/dummy_app`):

```sh
bundle install
bin/rails db:setup   # creates the SQLite DB, runs the migration, loads seeds
```

`db:setup` creates `rake_task_executions` and seeds ~60 realistic execution
records so the dashboard is interesting on first visit.

> If you prefer to see the exact developer integration path, the initializer and
> migration in this app are the output of:
>
> ```sh
> bin/rails generate rake_audit:install
> ```
>
> which writes `config/initializers/rake_audit.rb` and a timestamped
> `db/migrate/*_create_rake_task_executions.rb`. They are already checked in
> here so the example runs out of the box.

---

## 2. How the integration is wired

Three things connect the app to `rake_audit`:

1. **Initializer** — `config/initializers/rake_audit.rb` requires the adapter
   and sets it. The `require` is required: `rake_audit` does not auto-load its
   adapters.

   ```ruby
   require 'rake_audit/adapters/active_record_adapter'

   RakeAudit.configure do |config|
     config.adapter = RakeAudit::Adapters::ActiveRecordAdapter.new
   end
   ```

   Setting the adapter is what enables recording — the gem's Railtie only
   installs the `Rake::Task#execute` hook when an adapter is present.

2. **Migration** — `db/migrate/*_create_rake_task_executions.rb` creates the
   `rake_task_executions` table (SQLite stores the `arguments` column as `text`;
   the model casts it to/from JSON).

3. **Web UI** — `config/routes.rb` mounts the engine:

   ```ruby
   mount RakeAudit::Engine, at: '/rake_audit'
   ```

---

## 3. Run the demo tasks

Every task is recorded automatically — you do not write any auditing code.

| Task | Demonstrates |
|---|---|
| `bin/rails demo:hello` | A basic recorded **success** row |
| `bin/rails demo:slow_report` | `duration_ms` capture (~1500ms) |
| `bin/rails "demo:with_args[3,nightly]"` | The `arguments` column |
| `bin/rails demo:flaky` | **Failure** capture: `status`, `error_class`, `error_message` |
| `bin/rails demo:seed_audit_data` | Bulk-populates the dashboard with sample data |

Example:

```sh
$ bin/rails demo:hello
Hello from rake_audit! This run is recorded as status="success".

$ bin/rails "demo:with_args[3,nightly]"
Processing 3 item(s) for label 'nightly'.
  - item 1
  - item 2
  - item 3
The arguments hash is recorded on the audit row.

$ bin/rails demo:flaky
Attempting a flaky operation...
bin/rails aborted!
Simulated failure: the flaky task always blows up.
# ^ the run is still recorded — as status="failure" with the error captured.
```

---

## 4. Inspect recorded executions

**In the console:**

```sh
bin/rails runner 'p RakeAudit::TaskExecution.order(started_at: :desc).limit(5).map { |r| [r.task_name, r.status, r.duration_ms] }'
```

**In the Web UI** — start the server and open the dashboard:

```sh
bin/rails server
```

| URL | Page |
|---|---|
| <http://localhost:3000/> | Redirects to the dashboard |
| <http://localhost:3000/rake_audit> | Paginated execution list with filters |
| <http://localhost:3000/rake_audit/dashboard> | Aggregate stats (totals, success/failure, avg duration, top failed tasks) |
| <http://localhost:3000/rake_audit/executions/:id> | Single execution detail |

The Web UI is open in this demo. To restrict it, set `config.authenticate_with`
in `config/initializers/rake_audit.rb` (a commented example is included there).

---

## 5. Reset

```sh
bin/rails runner 'RakeAudit::TaskExecution.delete_all'   # clear records
bin/rails db:reset                                       # drop, recreate, re-seed
```

SQLite database files, logs, and tmp are git-ignored (`.gitignore`).
