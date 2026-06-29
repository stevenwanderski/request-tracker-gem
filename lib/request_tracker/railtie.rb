module RequestTracker
  class Railtie < ::Rails::Railtie
    initializer "request_tracker.middleware" do |app|
      app.middleware.use RequestTracker::Middleware
    end

    initializer "request_tracker.sidekiq_middleware" do |app|
      if defined?(Sidekiq)
        Sidekiq.configure_client do |config|
          config.client_middleware do |chain|
            chain.add RequestTracker::SidekiqClientMiddleware
          end
        end
      end
    end

    initializer "request_tracker.validate_env_vars" do |app|
      app.config.after_initialize do
        next if !RequestTracker.config.enabled_environments.include?(Rails.env)

        required = ["REQUEST_TRACKER_APP_ID", "REQUEST_TRACKER_API_TOKEN"]
        missing = required.select { |key| ENV[key].to_s.empty? }

        raise ConfigurationError.new(missing) if missing.any?
      end
    end
  end
end