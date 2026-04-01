# state_sync

A Ruby gem for fetching YAML-based feature flags and configuration from a GitHub or GitLab repository.
Values are loaded at startup and can optionally be kept fresh in the background.

## Installation

Add to your Gemfile:

```ruby
gem "state_sync"
```

Or install directly:

```bash
gem install state_sync
```

---

## Try it in IRB

First install the gem:

```bash
gem install state_sync
```

Then start IRB and require the gem:

```bash
irb
```

```ruby
require "state_sync"
```

Then in IRB:

```ruby
# GitHub
StateSync.configure do |config|
  config.provider = :github
  config.repo     = "your-org/your-repo"
  config.token    = "ghp_your_token_here"
end

customers = StateSync.load("config/customers.yml")
customers.data
customers["customer_ids"]

# Force a refresh
customers.reload!
```

---

## GitHub setup

### Create a token

**Fine-grained Personal Access Token (recommended):**

1. Go to **GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens**
2. Click **Generate new token**
3. Under **Repository access**, select the repo that holds your YAML files
4. Under **Permissions → Repository permissions**, set **Contents** to **Read-only**
5. Click **Generate token** and copy it

**Classic Personal Access Token:**

1. Go to **GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)**
2. Click **Generate new token (classic)**
3. Select the **`repo`** scope
4. Click **Generate token** and copy it

### Store the token

```bash
# .env (never commit this)
GITHUB_TOKEN=ghp_your_token_here
```

### Without auto refresh

Data is fetched once when the server starts. It does not change until the server restarts.

```ruby
StateSync.configure do |config|
  config.provider     = :github
  config.repo         = "your-org/your-repo"
  config.token        = ENV["GITHUB_TOKEN"]
  config.auto_refresh = false
end

customers = StateSync.load("config/customers.yml")
customers["customer_ids"]   # => [1001, 1002, 1003]
```

### With auto refresh

Data is fetched at startup and a background thread keeps it updated at the configured interval.

```ruby
StateSync.configure do |config|
  config.provider         = :github
  config.repo             = "your-org/your-repo"
  config.token            = ENV["GITHUB_TOKEN"]
  config.auto_refresh     = true
  config.refresh_interval = 300   # seconds
end

customers = StateSync.load("config/customers.yml")
customers["customer_ids"]   # => always current
```

---

## GitLab setup

### Create a token

1. Go to **GitLab → Edit profile → Access tokens**
2. Click **Add new token**
3. Give it a name and set an expiry date
4. Under **Select scopes**, check **`read_repository`**
5. Click **Create personal access token** and copy it

### Store the token

```bash
# .env (never commit this)
GITLAB_TOKEN=glpat_your_token_here
```

### Without auto refresh

```ruby
StateSync.configure do |config|
  config.provider     = :gitlab
  config.repo         = "your-org/your-repo"
  config.token        = ENV["GITLAB_TOKEN"]
  config.auto_refresh = false
end

customers = StateSync.load("config/customers.yml")
customers["customer_ids"]   # => [1001, 1002, 1003]
```

### With auto refresh

```ruby
StateSync.configure do |config|
  config.provider         = :gitlab
  config.repo             = "your-org/your-repo"
  config.token            = ENV["GITLAB_TOKEN"]
  config.auto_refresh     = true
  config.refresh_interval = 300   # seconds
end

customers = StateSync.load("config/customers.yml")
customers["customer_ids"]   # => always current
```

---

## Usage

```ruby
# Load a YAML file — fetches immediately on this line
customers = StateSync.load("config/customers.yml")

# Access data
customers.data              # => {"customer_ids" => [1001, 1002, 1003], "feature_x" => true}
customers["customer_ids"]   # => [1001, 1002, 1003]
customers["feature_x"]      # => true

# Force a manual refresh at any time
customers.reload!
```

### Example YAML file

```yaml
customer_ids:
  - 1001
  - 1002
  - 1003

feature_x: true
```

### Loading multiple files

You can load as many files as you need — each gets its own store with independent data and refresh cycle. Define them in your initializer and use them anywhere in your app:

```ruby
# config/initializers/state_sync.rb
StateSync.configure do |config|
  config.provider = :github
  config.repo     = "your-org/your-repo"
  config.token    = ENV["GITHUB_TOKEN"]
end

CUSTOMERS     = StateSync.load("config/customers.yml")
FEATURE_FLAGS = StateSync.load("config/feature_flags.yml")
ALLOWED_IPS   = StateSync.load("config/allowed_ips.yml")
```

```ruby
# Use anywhere in your app
CUSTOMERS["customer_ids"]
FEATURE_FLAGS["new_dashboard"]
ALLOWED_IPS["ips"]
```

### In a Rails controller

```ruby
class ApiController < ApplicationController
  def index
    render json: { allowed: CUSTOMERS["customer_ids"] }
  end
end
```

---

## Public repositories

No token is required for public repos. Unauthenticated requests are rate-limited to **60 requests/hour** (GitHub) so a token is still recommended, especially when `auto_refresh` is enabled.

---

## Error handling

```ruby
begin
  flags = StateSync.load("config/flags.yml")
rescue StateSync::ConfigurationError => e
  # Missing or invalid configuration
rescue StateSync::FetchError => e
  # Network error, bad token, file not found, etc.
end
```
