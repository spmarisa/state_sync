require "yaml"
require "ostruct"

# Holds the parsed contents of a single YAML file fetched from GitHub or GitLab.
# On initialization it fetches the file immediately.
class StateSync::Store
  def initialize(path)
    @path    = path
    @fetcher = fetcher_for(StateSync.configuration)

    fetch_and_cache
  end

  # Returns data in the format set by Configuration#data_format.
  # :struct (default) — dot-access via OpenStruct
  # :hash             — raw Ruby Hash / Array / scalar
  def data
    @data
  end

  # Shorthand key access (delegates to #data).
  def [](key)
    data[key]
  end

  # Force an immediate re-fetch from the configured provider.
  def reload!
    fetch_and_cache
    self
  end

  private

  def fetcher_for(config)
    case config.provider
    when :github then StateSync::GithubFetcher.new(config)
    when :gitlab then StateSync::GitlabFetcher.new(config)
    end
  end

  def fetch_and_cache
    content = @fetcher.fetch(@path)
    raw     = YAML.safe_load(content)
    @data   = StateSync.configuration.data_format == :struct ? to_struct(raw) : raw
  end

  def to_struct(value)
    case value
    when Hash  then OpenStruct.new(value.transform_values { |v| to_struct(v) })
    when Array then value.map { |v| to_struct(v) }
    else value
    end
  end
end
