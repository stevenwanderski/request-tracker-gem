module RequestTracker
  class Railtie < ::Rails::Railtie
    initializer "request_tracker.middleware" do |app|
      app.middleware.use RequestTracker::Middleware
    end

    initializer "request_tracker.validate_env_vars" do |app|
      required = ["REQUEST_TRACKER_APP_ID", "REQUEST_TRACKER_API_TOKEN"]
      missing = required.select { |key| ENV[key].to_s.empty? }

      raise ConfigurationError.new(missing) if missing.any?
    end
  end
end