require "kaminari"

module RequestTracker
  class Engine < ::Rails::Engine
    isolate_namespace RequestTracker

    initializer "request_tracker.assets", before: :append_assets_path do |app|
      app.config.assets.paths << root.join("app/assets/builds").to_s
      app.config.assets.paths << root.join("app/assets/javascripts").to_s

      # Propshaft serves anything on the load path with no further config.
      # Sprockets, in contrast, refuses to serve (in production) any asset
      # that isn't explicitly listed for precompilation -- so these need to
      # be added here rather than requiring every host app to hand-edit its
      # own app/assets/config/manifest.js.
      app.config.assets.precompile ||= []
      app.config.assets.precompile += %w[
        request_tracker/application.css
        request_tracker/application.js
        request_tracker/rails-ujs.js
      ]
    end

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

        Sidekiq.configure_server do |config|
          config.server_middleware do |chain|
            chain.add RequestTracker::SidekiqServerMiddleware
          end
        end
      end
    end

    initializer "request_tracker.mailer_tracking" do |app|
      if defined?(ActionMailer)
        ActionMailer::Base.register_interceptor(RequestTracker::MailerInterceptor)
        RequestTracker::MailerEnqueueSubscriber.subscribe
        RequestTracker::MailerPerformSubscriber.subscribe
      end
    end
  end
end
