class StateSync::Configuration
  PROVIDERS = %i[github gitlab].freeze

  attr_accessor :provider, :repo, :token, :auto_refresh, :auto_refresh_interval

  def initialize
    @provider         = :github
    @auto_refresh     = false
    @auto_refresh_interval = 300
  end

  def validate!
    unless PROVIDERS.include?(provider)
      raise StateSync::ConfigurationError, "provider must be :github or :gitlab"
    end

    raise StateSync::ConfigurationError, "repo must be set (e.g. \"owner/repo\")" if repo.nil? || repo.strip.empty?

    if auto_refresh && (auto_refresh_interval.nil? || auto_refresh_interval <= 0)
      raise StateSync::ConfigurationError, "auto_refresh_interval must be a positive number of seconds when auto_refresh is true"
    end
  end
end
