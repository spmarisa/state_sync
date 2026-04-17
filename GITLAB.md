# GitLab Setup for state_sync

`state_sync` reads YAML files directly from a GitLab project using the GitLab Repository Files API.

---

## Public projects

No token is required for public projects. You can omit `config.token` entirely.
A token is still recommended to avoid hitting rate limits.

---

## Private projects

A GitLab personal access token with `read_repository` scope is required.

---

## Creating a token

1. Go to **GitLab → Edit profile → Access tokens**
2. Click **Add new token**
3. Give it a name (e.g. `state_sync`) and set an expiry date
4. Under **Select scopes**, check **`read_repository`**
5. Click **Create personal access token** and copy it immediately — GitLab will not show it again

---

## Storing the token safely

Never hardcode a token in your source code. Use an environment variable:

```bash
# .env (not committed to git)
GITLAB_TOKEN=glpat_your_token_here
```

Then reference it in your configuration:

```ruby
StateSync.configure do |config|
  config.provider = :gitlab
  config.token    = ENV["GITLAB_TOKEN"]
  config.repo     = "your-org/your-repo"
end
```

If you use Rails credentials, you can also store it there:

```bash
rails credentials:edit
```

```yaml
gitlab:
  state_sync_token: glpat_your_token_here
```

```ruby
config.token = Rails.application.credentials.dig(:gitlab, :state_sync_token)
```

---

## Rate limits

GitLab rate limits vary by plan and instance. Files over 10 MB are limited to 5 requests/minute.
Always use a token in production.

---

## Example

```ruby
StateSync.configure do |config|
  config.provider = :gitlab
  config.repo     = "your-org/your-repo"
  config.token    = ENV["GITLAB_TOKEN"]
end

customers = StateSync.load("config/customers.yml")
customers["customer_ids"]   # => [1001, 1002, 1003]
```
