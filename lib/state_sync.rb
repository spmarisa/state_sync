require "state_sync/version"
require "state_sync/errors"
require "state_sync/configuration"
require "state_sync/store"
Dir[File.join(__dir__, "state_sync/fetchers/*.rb")].each { |f| require f }

module StateSync
  class << self
    def configure
      yield configuration
      configuration.validate!
    end

    def configuration
      @configuration ||= Configuration.new
    end

    # Loads a YAML file from the configured provider (GitHub or GitLab) and returns a Store.
    # The file is fetched immediately on this call.
    #
    # Example:
    #   customers = StateSync.load("config/customers.yml")
    #   customers["allowed_ids"]  # => [1, 2, 3]
    def load(path)
      Store.new(path)
    end
  end
end
