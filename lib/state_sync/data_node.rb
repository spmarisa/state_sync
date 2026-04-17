# Wraps a parsed YAML Hash so that keys are accessible as methods.
# Nested Hashes are recursively wrapped; nested Arrays have their Hash
# elements wrapped too.
class StateSync::DataNode
  def initialize(hash)
    @hash = hash
  end

  def method_missing(name, *args)
    key = name.to_s
    @hash.key?(key) ? wrap(@hash[key]) : super
  end

  def respond_to_missing?(name, include_private = false)
    @hash.key?(name.to_s) || super
  end

  def [](key)
    wrap(@hash[key.to_s])
  end

  def to_h
    @hash
  end

  def self.wrap(value)
    case value
    when Hash  then new(value)
    when Array then value.map { |v| v.is_a?(Hash) ? new(v) : v }
    else value
    end
  end

  private

  def wrap(value)
    self.class.wrap(value)
  end
end
