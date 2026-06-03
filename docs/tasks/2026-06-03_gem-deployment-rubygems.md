# Implementation Plan: Gem Deployment to RubyGems.org

## Requirements Restatement

- Prepare `rake_audit` (v0.1.0) for public release on RubyGems.org
- Ensure the gemspec is production-quality (metadata, changelog link, required fields)
- Add a `CHANGELOG.md` documenting the initial release
- Set up a GitHub Actions workflow to automate future releases on version tag push
- Publish the gem to RubyGems.org under the `eraxel.dev@gmail.com` account

---

## Implementation Phases

### Phase 1: Gemspec Polish
- Add `spec.metadata['changelog_uri']` pointing to `CHANGELOG.md` on GitHub
- Exclude the built `.gem` file and `spec/` directory from the published artifact (add `.gemignore` or tighten `spec.files`)
- Verify `spec.files` includes all required files (views, migrations, generator templates)
- Confirm `spec.required_ruby_version` and dependency version ranges are correct

### Phase 2: Changelog
- Create `CHANGELOG.md` at the repo root
- Document v0.1.0: initial release, features (ActiveRecord/Redis/Mongo adapters, Web UI, Rails generator)
- Add `CHANGELOG.md` to `spec.files`

### Phase 3: GitHub Actions Release Workflow
- Create `.github/workflows/release.yml`
- Trigger on `v*` tag push (e.g. `v0.1.0`)
- Steps: checkout → setup Ruby → `gem build` → `gem push` using `RUBYGEMS_API_KEY` secret
- Add `GEM_HOST_API_KEY` secret configuration instructions in a comment

### Phase 4: Publish v0.1.0
- Clean the built `rake_audit-0.1.0.gem` artifact from the repo (it should not be committed)
- Create and push the `v0.1.0` git tag to trigger the workflow
- Alternatively, run `gem push rake_audit-0.1.0.gem` manually for the first release

---

## Dependencies

- RubyGems.org account with `eraxel.dev@gmail.com` (must exist and own the `rake_audit` name)
- `RUBYGEMS_API_KEY` GitHub Actions secret (obtained from RubyGems.org profile)
- MFA-required gem (`rubygems_mfa_required = 'true'` is already set — OTP needed for manual push)

---

## Risks

- **HIGH**: The gem name `rake_audit` may already be taken on RubyGems.org — must verify before publishing
- **MEDIUM**: `rubygems_mfa_required = 'true'` requires the RubyGems account to have MFA enabled; automated push via API key still works but the account must be MFA-enrolled
- **LOW**: `.gem` artifact is currently sitting in the repo root — should be gitignored before tagging
- **LOW**: `spec.files` glob may inadvertently include `spec/` or test fixtures — worth a dry-run inspection
