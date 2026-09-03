module RequestTracker
  class Middleware
    IGNORED_PREFIXES = %w[/assets /packs /favicon.ico /cable].freeze
    DEFAULT_API_URL = "https://request-tracker-33339aabecdd.herokuapp.com/requests".freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      run(env)
    end

    def run(env)
      if !RequestTracker.config.enabled_environments.include?(Rails.env)
        return @app.call(env)
      end

      api_url = ENV.fetch("REQUEST_TRACKER_API_URL", DEFAULT_API_URL)
      ignored_hosts = [api_url]

      RequestTracker::Current.outbound_calls = []
      RequestTracker::Current.enqueued_jobs = []
      RequestTracker::Current.sent_mailers = []
      RequestTracker::Current.enqueued_mailers = []

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
          stack_trace: RequestTracker::BacktraceContext.build(e)
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
        referer: request.referer,
        path: request.path,
        method: request.method,
        status_code: status,
        request_body: request.filtered_parameters,
        user_agent: request.user_agent,
        headers: request_headers(request),
        outbound_calls: RequestTracker::Current.outbound_calls,
        enqueued_jobs: RequestTracker::Current.enqueued_jobs,
        sent_mailers: RequestTracker::Current.sent_mailers,
        enqueued_mailers: RequestTracker::Current.enqueued_mailers,
        current_user: current_user_data(request),
        api_token: ENV["REQUEST_TRACKER_API_TOKEN"]
      }

      payload[:location] = headers["Location"] if headers.present?
      payload[:error] = error_payload if error_payload.present?

      Thread.new(payload) do |payload|
        api_url = ENV.fetch("REQUEST_TRACKER_API_URL", DEFAULT_API_URL)

        begin
          response = Net::HTTP.post(
            URI(api_url),
            payload.to_json,
            "Content-Type" => "application/json"
          )
          warn "[request_tracker] POST /requests rejected: #{response.code} #{response.body}" if !response.is_a?(Net::HTTPSuccess)
        rescue => e
          warn "[request_tracker] Background POST /requests failed: #{e.class}: #{e.message}"
        end
      end
    end

    private

    # The parent app's callback is arbitrary code we don't control, running
    # inside Rack middleware on every single request -- a bug in it must never
    # take down the actual app, so it's never allowed to raise past here.
    #
    # Whatever the callback returns -- an ID, a string, or a full model
    # instance -- is passed through #as_json so it travels as plain,
    # JSON-safe data (a Hash for a model, or itself for a scalar).
    def current_user_data(request)
      return nil if !RequestTracker.config.current_user

      RequestTracker.config.current_user.call(request)&.as_json
    rescue => e
      warn "[request_tracker] current_user callback raised: #{e.class}: #{e.message}"
      nil
    end

    # Rack stuffs request headers into env as HTTP_FOO_BAR alongside a pile of
    # unrelated server/interpreter state (rack.*, action_dispatch.*, PATH,
    # GATEWAY_INTERFACE, ...) -- the HTTP_ prefix is what separates an actual
    # header from that noise. HTTP_VERSION is the one HTTP_-prefixed key that
    # isn't a header (it's the protocol version, e.g. "HTTP/1.1"), so it's
    # excluded explicitly. Content-Type/Content-Length are real headers too
    # but Rack promotes them out of the HTTP_ namespace, so they're added back
    # in by hand.
    def request_headers(request)
      headers = {}

      request.env.each do |key, value|
        next if !value.is_a?(String)
        next if key == "HTTP_VERSION"

        if key.start_with?("HTTP_")
          name = key.sub(/\AHTTP_/, "").split("_").map(&:capitalize).join("-")
          headers[name] = value
        elsif %w[CONTENT_TYPE CONTENT_LENGTH].include?(key)
          name = key.split("_").map(&:capitalize).join("-")
          headers[name] = value
        end
      end

      headers
    end
  end
end