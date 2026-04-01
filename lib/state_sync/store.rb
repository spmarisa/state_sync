require "yaml"

# Holds the parsed contents of a single YAML file fetched from GitHub or GitLab.
# On initialization it fetches the file immediately. If auto_refresh is
# enabled a background thread keeps the data current at the configured interval.
class StateSync::Store
  def initialize(path)
    @path    = path
    @fetcher = fetcher_for(StateSync.configuration)
    @mutex   = Mutex.new

    fetch_and_cache

    start_background_refresh if StateSync.configuration.auto_refresh
  end

  # Returns the parsed YAML data (Hash or Array depending on file content).
  def data
    @mutex.synchronize { @data }
  end

  # Shorthand key access when the YAML root is a Hash.
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
    parsed  = YAML.safe_load(content)
    @mutex.synchronize { @data = parsed }
  end

  def start_background_refresh
    interval = StateSync.configuration.auto_refresh_interval

    Thread.new do
      Thread.current.daemon = true
      loop do
        sleep interval
        begin
          fetch_and_cache
        rescue => e
          warn "[StateSync] Failed to refresh '#{@path}': #{e.message}"
        end
      end
    end
  end
end
