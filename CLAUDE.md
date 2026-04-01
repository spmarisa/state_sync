# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bundle install --path vendor/bundle   # install dependencies
bundle exec rspec                     # run all tests
bundle exec rspec spec/state_sync/store_spec.rb   # run a single spec file
gem build state_sync.gemspec          # build the .gem file
gem install state_sync-*.gem          # install locally
```

## Code style

**Always use compact class/module syntax:**
```ruby
# correct
class StateSync::Configuration
end

# never
module StateSync
  class Configuration
  end
end
```
Exception: `lib/state_sync.rb` defines the top-level `module StateSync` and `lib/state_sync/version.rb` uses `module StateSync` for gemspec compatibility — those stay as-is.

## Architecture

`state_sync` is a Ruby gem. Entry point is `lib/state_sync.rb`.

### Key classes

- **`StateSync` (module)** — public API. `StateSync.configure { |c| }` sets global config; `StateSync.load("path/to/file.yml")` returns a `Store`.
- **`StateSync::Configuration`** — holds `provider`, `repo`, `github_token`, `gitlab_token`, `auto_refresh`, `auto_refresh_interval`. Validated on first fetch.
- **`StateSync::GithubFetcher`** (`lib/state_sync/fetchers/`) — calls `GET /repos/{owner}/{repo}/contents/{path}`, decodes base64 response, returns raw YAML string.
- **`StateSync::GitlabFetcher`** (`lib/state_sync/fetchers/`) — calls GitLab raw file endpoint with `ref=HEAD` (always default branch), returns raw YAML string.
- **`StateSync::Store`** — wraps a single loaded file. Fetches on init, exposes `data` / `[]` / `reload!`. When `auto_refresh` is true, spawns a background `Thread` that re-fetches every `auto_refresh_interval` seconds; errors are warned to stderr and previous data is kept.

### File organisation

Fetchers live in `lib/state_sync/fetchers/`. Add new provider fetchers there.

### Refresh modes

- `auto_refresh: false` (default) — fetch once at startup, never again.
- `auto_refresh: true` — fetch at startup + background thread refreshes every `auto_refresh_interval` seconds.

### Auth

- GitHub public repos: token optional (60 req/hour unauthenticated vs 5,000 authenticated).
- GitHub private repos: `github_token` required. See `GITHUB_SETUP.md`.
- GitLab: `gitlab_token` with `read_repository` scope.
