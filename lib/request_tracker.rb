require_relative "request_tracker/version"
require_relative "request_tracker/railtie"
require_relative "request_tracker/middleware"
require_relative "request_tracker/sidekiq_client_middleware"
require_relative "request_tracker/current"
require_relative "request_tracker/net_http_patch"
require_relative "request_tracker/configuration_error"

module RequestTracker
  class Error < StandardError; end
end