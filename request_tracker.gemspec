require_relative "lib/request_tracker/version"

Gem::Specification.new do |spec|
  spec.name = "request_tracker"
  spec.version = RequestTracker::VERSION
  spec.authors = ["Steven Wanderski"]
  spec.email = ["steven.wanderski@gmail.com"]

  spec.summary  = "A minimal, sane request tracker for Rails."
  spec.description = "A minimal, sane request tracker for Rails."
  spec.homepage = "https://github.com/stevenwanderski/request-tracker-gem"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.0.0"

  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.add_dependency "rails", ">= 7.0"
end