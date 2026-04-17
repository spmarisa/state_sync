# state_sync

A Ruby gem for fetching YAML-based feature flags and configuration from a GitHub or GitLab repository.
Values are loaded at startup via `StateSync.load`.

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

## Configuration

Token setup: [GITHUB.md](GITHUB.md) | [GITLAB.md](GITLAB.md)

```ruby
# config/initializers/state_sync.rb
StateSync.configure do |config|
  config.provider     = :github          # :github or :gitlab
  config.repo         = "your-org/your-repo"  # "owner/repo" on GitHub or GitLab
  config.token        = ENV["GITHUB_TOKEN"]   # optional for public repos, but always set in production — unauthenticated requests are limited to 60/hr vs 5,000/hr with a token
  config.data_format  = :struct          # :struct (default) — dot-access via OpenStruct; :hash — plain Ruby Hash
end
```

---

## Usage

```ruby
# Load a YAML file — fetches immediately on this line
CUSTOMERS = StateSync.load("config/customers.yml")

# Access data
CUSTOMERS.data              # => {"customer_ids" => [1001, 1002, 1003], "feature_x" => true}
CUSTOMERS["customer_ids"]   # => [1001, 1002, 1003]
CUSTOMERS["feature_x"]      # => true

# Force a manual refresh at any time
CUSTOMERS.reload!
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

You can load as many files as you need — each gets its own store with independent data. Define them in your initializer and use them anywhere in your app:

```ruby
# config/initializers/state_sync.rb
StateSync.configure do |config|
  config.provider = :github
  config.repo     = "your-org/your-repo"  # "owner/repo" on GitHub or GitLab
  config.token    = ENV["GITHUB_TOKEN"]
end

CUSTOMERS       = StateSync.load("config/customers.yml")
FEATURE_FLAGS   = StateSync.load("config/feature_flags.yml")
PAYMENT_METHODS = StateSync.load("config/payment_methods.yml")
PAYMENT_LIMITS  = StateSync.load("config/payment_limits.yml")
```

```ruby
# Use anywhere in your app
CUSTOMERS["customer_ids"]
FEATURE_FLAGS["new_checkout_flow"]
PAYMENT_METHODS["enabled"]
PAYMENT_LIMITS["daily_limit"]
```
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

StateSync.configure do |config|
  config.provider = :github
  config.repo     = "spmarisa/state_sync_data"  # public repo, no token needed
end

customers = StateSync.load("allowed_customers.yml")
customers.data
customers["customer_ids"]

# Force a refresh
customers.reload!
```
