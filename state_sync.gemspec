require_relative "lib/state_sync/version"

Gem::Specification.new do |spec|
  spec.name    = "state_sync"
  spec.version = StateSync::VERSION
  spec.authors = ["Phaneendra Marisa"]
  spec.email   = ["phaneendra.marisa@gmail.com"]
  spec.summary = "Fetch and auto-refresh YAML-based feature flags and config from a Git repository."

  spec.homepage = "https://github.com/spmarisa/state_sync"
  spec.license  = "WTFPL"

  spec.required_ruby_version = ">= 2.5.0"

  spec.files = Dir["lib/**/*.rb", "README.md", "GITHUB.md", "GITLAB.md", "LICENSE"]

  spec.add_development_dependency "rspec",   "~> 3.13"
  spec.add_development_dependency "webmock", "~> 3.23"
end
