# Implementation Plan: Example Rails App for `rake_audit`

## Overview

Add a self-contained Rails 7 application under `examples/dummy_app/` in the gem repo that integrates `rake_audit` via a local path-based gem reference, uses SQLite, and demonstrates the gem's full feature set: automatic auditing of Rake tasks (success and failure paths), the ActiveRecord adapter, querying recorded executions, and the mounted Web UI dashboard.

## Gem Understanding

- `rake_audit` prepends a hook into `Rake::Task#execute` (`lib/rake_audit/task_patch.rb`) that records every task run: `task_name`, `arguments`, `started_at`, `finished_at`, `duration_ms`, `status` (`success`/`failure`), `error_class`, `error_message`, `hostname`, `pid`, `ruby_version`, `rails_env`.
- Integration in Rails requires three things:
  1. `rails generate rake_audit:install` → writes `config/initializers/rake_audit.rb` + a timestamped migration creating `rake_task_executions`.
  2. Setting `config.adapter = RakeAudit::Adapters::ActiveRecordAdapter.new` in the initializer.
  3. Optionally mounting `RakeAudit::Engine` at `/rake_audit` in `config/routes.rb` for the Web UI.
- The Railtie installs the patch in `config.after_initialize` only when an adapter is configured.
- The model `RakeAudit::TaskExecution` (table `rake_task_executions`) is autoloaded via the Engine's `app/` path. SQLite is fully supported.

## Requirements

- Create a real, runnable Rails app inside the gem repo that consumes `rake_audit` from the local source (path gem), not from RubyGems — so the example always tracks the current gem code.
- Database must be SQLite.
- Demonstrate end-to-end integration: install generator output, adapter wiring, migration, mounting the Web UI.
- Provide sample Rake tasks that exercise auditing: at least one that succeeds, one that fails (error capture), and one that takes arguments.
- Make it obvious and copy-pasteable for a developer evaluating the gem.

## Proposed Directory Structure

```
examples/dummy_app/
├── README.md                     # how to run the example (step-by-step)
├── Gemfile                       # gem 'rake_audit', path: '../..'
├── Rakefile
├── config.ru
├── .gitignore                    # ignore db/*.sqlite3, log/, tmp/
├── bin/
│   ├── rails
│   ├── rake
│   └── setup
├── config/
│   ├── application.rb
│   ├── boot.rb
│   ├── environment.rb
│   ├── database.yml              # SQLite (development + test)
│   ├── routes.rb                 # mount RakeAudit::Engine, at: '/rake_audit'
│   ├── initializers/
│   │   └── rake_audit.rb         # adapter = ActiveRecordAdapter.new
│   └── environments/
│       ├── development.rb
│       └── test.rb
├── app/
│   ├── models/application_record.rb
│   └── controllers/application_controller.rb
├── db/
│   ├── migrate/
│   │   └── <ts>_create_rake_task_executions.rb
│   ├── seeds.rb
│   └── schema.rb
└── lib/
    └── tasks/
        └── demo.rake
```

## Sample Rake Tasks (`lib/tasks/demo.rake`)

1. **`demo:hello`** — trivial successful task; demonstrates basic recorded success.
2. **`demo:slow_report`** — sleeps ~1.5s; demonstrates `duration_ms` capture.
3. **`demo:with_args[count,label]`** — accepts arguments; demonstrates the `arguments` column.
4. **`demo:flaky`** — raises `RuntimeError`; demonstrates `status: 'failure'`, `error_class`, `error_message` capture.
5. **`demo:seed_audit_data`** — populates the Web UI dashboard with a spread of realistic execution records.

## Implementation Phases

### Phase 0: Pre-flight verification

1. **Confirm adapter require path** (`lib/rake_audit/adapters/active_record_adapter.rb`)
   - Verify whether `ActiveRecordAdapter` is auto-loaded by the Engine or must be explicitly required in the initializer.
   - Determines whether the initializer needs an explicit `require 'rake_audit/adapters/active_record_adapter'`.
   - Risk: Medium

### Phase 1: Rails app skeleton

2. **Generate minimal app** (`config/*`, `bin/*`, `app/*`)
   - Create a slim Rails 7 app using `rails new examples/dummy_app --minimal --database=sqlite3 --skip-git`, then prune to the listed structure.
   - Risk: Medium — pruning to a clean example is the main effort.

3. **Configure SQLite** (`config/database.yml`)
   - SQLite3 adapter for `development` and `test`, db files under `db/`.
   - Risk: Low

4. **Point Gemfile at local gem** (`Gemfile`)
   - `gem 'rake_audit', path: '../..'`; include `sqlite3 ~> 1.4` to align with gem's dev dependencies.
   - Risk: Low

### Phase 2: Wire up `rake_audit`

5. **Run install generator** (`config/initializers/rake_audit.rb`, `db/migrate/<ts>_create_rake_task_executions.rb`)
   - `bin/rails generate rake_audit:install` or hand-place equivalents from gem templates.
   - Demonstrates the exact developer integration path.
   - Risk: Low

6. **Enable the ActiveRecord adapter** (`config/initializers/rake_audit.rb`)
   - Set `config.adapter = RakeAudit::Adapters::ActiveRecordAdapter.new`; add require if needed (from Phase 0). Leave capture_* options at defaults with explanatory comments.
   - Risk: Medium (load order)

7. **Mount the Web UI** (`config/routes.rb`)
   - `mount RakeAudit::Engine, at: '/rake_audit'`. Leave `authenticate_with` unset (open) for demo, with a comment showing how to restrict.
   - Risk: Low

8. **Migrate** (`db/schema.rb`)
   - `bin/rails db:create db:migrate` to produce `rake_task_executions` and commit `schema.rb`.
   - Risk: Low

### Phase 3: Demo Rake tasks + data

9. **Author demo tasks** (`lib/tasks/demo.rake`)
   - Implement the five tasks with clear `puts` output and inline comments explaining what each demonstrates about auditing.
   - Risk: Low

10. **Seed audit data** (`db/seeds.rb`)
    - Populate a realistic spread of executions so `/rake_audit/dashboard` shows non-trivial stats on first visit.
    - Risk: Low

### Phase 4: Documentation

11. **Write the example README** (`examples/dummy_app/README.md`)
    - Step-by-step: `bundle install`, `bin/rails db:setup`, run each `demo:*` task, observe records via console and at `http://localhost:3000/rake_audit`. Include expected output snippets.
    - Risk: Low

12. **Link from gem's top-level README** (`README.md`)
    - Add a short "Try the example app" pointer to `examples/dummy_app/`.
    - Risk: Low

### Phase 5: Hygiene

13. **Gitignore + gemspec isolation check** (`examples/dummy_app/.gitignore`, `rake_audit.gemspec`)
    - Ignore `db/*.sqlite3`, `log/`, `tmp/`, `.bundle`.
    - Verify the gemspec `spec.files` globs do NOT include `examples/` so it stays out of the published gem.
    - Risk: Medium

## Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| Adapter class not auto-required → `NameError` on boot | Medium | Phase 0 verification; add explicit require in initializer if needed |
| `rails new` dumps a heavy app that obscures the demo | Medium | Use `--minimal` and prune to the listed structure |
| Example accidentally packaged into the published gem | Medium | Phase 5 gemspec glob review; `gem build` file-list check |
| Misconfigured initializer silently records nothing | Medium | README explicitly calls out adapter line is required; demo verifies a record exists after first task |
| SQLite gem version incompatibility | Low | Align `sqlite3 ~> 1.4` with the gem's dev group |

## Success Criteria

- [ ] `examples/dummy_app/` boots with `gem 'rake_audit', path: '../..'`
- [ ] SQLite is the only database backend used
- [ ] `bin/rails db:setup` creates `rake_task_executions`
- [ ] Running `demo:*` tasks writes correct audit rows (success, failure, args, duration)
- [ ] `/rake_audit`, `/rake_audit/dashboard`, `/rake_audit/executions/:id` render with seeded data
- [ ] Example README walks a developer through it end-to-end
- [ ] Built gem (`gem build`) does NOT include `examples/`
