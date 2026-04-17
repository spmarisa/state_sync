class StateSync::Configuration
  PROVIDERS    = %i[github gitlab].freeze
  DATA_FORMATS = %i[struct hash].freeze

  attr_accessor :provider, :repo, :token, :data_format

  def initialize
    @provider    = :github
    @data_format = :struct
  end

  def validate!
    unless PROVIDERS.include?(provider)
      raise StateSync::ConfigurationError, "provider must be :github or :gitlab"
    end

    raise StateSync::ConfigurationError, "repo must be set (e.g. \"owner/repo\")" if repo.nil? || repo.strip.empty?

    unless DATA_FORMATS.include?(data_format)
      raise StateSync::ConfigurationError, "data_format must be :struct or :hash"
    end
  end
end
