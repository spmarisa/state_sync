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

Then start IRB and require the gem:

```bash
irb
```

Then in IRB:

```ruby
require "state_sync"

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

## Configuration

Token setup: [GITHUB.md](GITHUB.md) | [GITLAB.md](GITLAB.md)

```ruby
StateSync.configure do |config|
  config.provider         = :github          # :github or :gitlab
  config.repo             = "your-org/your-repo"
  config.token            = ENV["GITHUB_TOKEN"]  # optional for public repos
  config.auto_refresh     = false            # true or false (default: false)
  config.auto_refresh_interval = 300              # seconds, only required when auto_refresh is true
end

customers = StateSync.load("config/customers.yml")
customers["customer_ids"]
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
