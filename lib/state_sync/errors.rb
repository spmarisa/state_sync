class StateSync::Error             < StandardError; end
class StateSync::ConfigurationError < StateSync::Error; end
class StateSync::FetchError         < StateSync::Error; end
