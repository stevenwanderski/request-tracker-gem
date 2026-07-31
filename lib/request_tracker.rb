require_relative "request_tracker/configuration"
require_relative "request_tracker/configuration_error"
require_relative "request_tracker/version"
require_relative "request_tracker/railtie"
require_relative "request_tracker/middleware"
require_relative "request_tracker/sidekiq_client_middleware"
require_relative "request_tracker/sidekiq_server_middleware"
require_relative "request_tracker/job_log_reporter"
require_relative "request_tracker/current"
require_relative "request_tracker/net_http_patch"
require_relative "request_tracker/mailer_interceptor"
require_relative "request_tracker/mailer_enqueue_subscriber"
require_relative "request_tracker/mailer_perform_subscriber"

module RequestTracker
  class Error < StandardError; end

  def self.configure
    yield config
  end

  def self.config
   @config ||= Configuration.new
  end
end