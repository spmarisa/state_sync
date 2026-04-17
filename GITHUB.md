# GitHub Setup for state_sync

`state_sync` reads YAML files directly from a GitHub repository using the GitHub Contents API.

---

## Public repositories

No token is required. You can omit `config.token` entirely.
However, unauthenticated requests are rate-limited to **60 requests/hour** per IP.
It is recommended to always provide a token even for public repos (authenticated limit is 5,000/hour).

---

## Private repositories

A GitHub token with read access to the repository is required.

---

## Creating a token

### Option A — Fine-grained Personal Access Token (recommended)

Fine-grained tokens let you limit access to specific repositories and specific permissions.

1. Go to **GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens**
2. Click **Generate new token**
3. Set a name (e.g. `state_sync`) and an expiration
4. Under **Repository access**, select **Only select repositories** and pick the repo that holds your YAML files
5. Under **Permissions → Repository permissions**, find **Contents** and set it to **Read-only**
6. Click **Generate token** and copy it immediately — GitHub will not show it again

### Option B — Classic Personal Access Token

1. Go to **GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)**
2. Click **Generate new token (classic)**
3. Set a note and expiration
4. Select the **`repo`** scope (grants full read/write to private repos — use fine-grained tokens if you want narrower access)
5. Click **Generate token** and copy it

---

## Storing the token safely

Never hardcode a token in your source code. Use an environment variable:

```bash
# .env (not committed to git)
GITHUB_TOKEN=ghp_your_token_here
```

Then reference it in your configuration:

```ruby
StateSync.configure do |config|
  config.provider = :github
  config.token    = ENV["GITHUB_TOKEN"]
  config.repo     = "your-org/your-repo"
end
```

If you use Rails credentials, you can also store it there:

```bash
rails credentials:edit
```

```yaml
github:
  state_sync_token: ghp_your_token_here
```

```ruby
config.token = Rails.application.credentials.dig(:github, :state_sync_token)
```

---

## Rate limits

| Authentication        | Requests per hour |
|-----------------------|-------------------|
| None (public repos)   | 60                |
| Personal Access Token | 5,000             |

---

## Example

```ruby
StateSync.configure do |config|
  config.provider = :github
  config.repo     = "your-org/your-repo"
  config.token    = ENV["GITHUB_TOKEN"]
end

customers = StateSync.load("config/customers.yml")
customers["customer_ids"]   # => [1001, 1002, 1003]
```
