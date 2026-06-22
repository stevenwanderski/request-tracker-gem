module RequestTracker
  class Middleware
    IGNORED_PREFIXES = %w[/assets /packs /favicon.ico /cable].freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      return run(env) unless Rails.env.development?

      RequestTracker::Middleware.send(:remove_const, :IGNORED_PREFIXES) if RequestTracker::Middleware.const_defined?(:IGNORED_PREFIXES)
      load __FILE__
      load File.join(__dir__, 'net_http_patch.rb')
      ::RequestTracker::Middleware.new(@app).run(env)
    end

    def run(env)
      ignored_hosts = ["localhost:3001", "request-tracker-33339aabecdd.herokuapp.com"]

      RequestTracker::Current.outbound_calls = []
      RequestTracker::Current.enqueued_jobs = []

      request = ActionDispatch::Request.new(env)

      if IGNORED_PREFIXES.any? { |prefix| request.path.starts_with?(prefix) }
        return @app.call(env)
      end

      if ignored_hosts.include?(request.host_with_port)
        return @app.call(env)
      end

      request.session[:flow_id] ||= SecureRandom.uuid

      begin
        status, headers, response = @app.call(env)
      rescue => e
        error_payload = {
          error_class: e.class,
          message: e.message,
          stack_trace: e.backtrace
        }

        report(request: request, status: "500", headers: headers, error_payload: error_payload)

        raise
      end

      report(request: request, status: status, headers: headers)

      [status, headers, response]
    end

    def report(request:, status:, headers:, error_payload: nil)
      payload = {
        flow_id: request.session[:flow_id],
        app_id: ENV["REQUEST_TRACKER_APP_ID"],
        path: request.path,
        method: request.method,
        status_code: status,
        request_body: request.filtered_parameters,
        outbound_calls: RequestTracker::Current.outbound_calls,
        enqueued_jobs: RequestTracker::Current.enqueued_jobs,
        api_token: ENV["REQUEST_TRACKER_API_TOKEN"]
      }

      payload[:location] = headers["Location"] if headers.present?
      payload[:error] = error_payload if error_payload.present?

      Thread.new(payload) do |payload|
        begin
          Net::HTTP.post(
            URI("https://request-tracker-33339aabecdd.herokuapp.com/requests"),
            payload.to_json,
            "Content-Type" => "application/json"
          )
        rescue => e
          ap "Background POST /requests failed: #{e.class}: #{e.message}"
        end
      end
    end
  end
end