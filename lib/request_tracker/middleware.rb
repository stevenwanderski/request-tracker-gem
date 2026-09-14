module RequestTracker
  class Middleware
    IGNORED_PREFIXES = %w[/assets /packs /favicon.ico /cable].freeze

    # The dashboard's own mount path is chosen by the host app (`mount
    # RequestTracker::Engine => "/wherever"`), so it can't be matched by
    # prefix the way IGNORED_PREFIXES is. Instead this is checked after
    # dispatch, against whichever controller actually served the request --
    # which also correctly respects any auth constraint the host wraps the
    # mount in, unlike trying to pre-recognize the route ourselves.
    ENGINE_CONTROLLER_PREFIX = "#{RequestTracker.name.underscore}/".freeze

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

      RequestTracker::Current.outbound_calls = []
      RequestTracker::Current.enqueued_jobs = []
      RequestTracker::Current.sent_mailers = []
      RequestTracker::Current.enqueued_mailers = []

      request = ActionDispatch::Request.new(env)

      if IGNORED_PREFIXES.any? { |prefix| request.path.starts_with?(prefix) }
        return @app.call(env)
      end

      request.session[:flow_id] ||= SecureRandom.uuid

      begin
        status, headers, response = @app.call(env)
      rescue => e
        if !request_tracker_route?(request)
          error_payload = {
            error_class: e.class,
            message: e.message,
            stack_trace: RequestTracker::BacktraceContext.build(e)
          }

          report(request: request, status: "500", headers: headers, error_payload: error_payload)
        end

        raise
      end

      return [status, headers, response] if request_tracker_route?(request)

      response_body, response = capture_json_response_body(headers, response)

      report(request: request, status: status, headers: headers, response_body: response_body)

      [status, headers, response]
    end

    # A failure here must never take down the actual request -- whatever
    # happens inside this method, the host app's response always wins.
    def report(request:, status:, headers:, response_body: nil, error_payload: nil)
      ActiveRecord::Base.transaction do
        req = RequestTracker::Request.new(
          flow_id: request.session[:flow_id],
          referer: request.referer,
          path: request.path,
          method: request.method,
          status_code: status.to_s,
          request_body: request.filtered_parameters,
          user_agent: request.user_agent,
          headers: request_headers(request),
          response_body: response_body,
          outbound_calls: RequestTracker::Current.outbound_calls,
          job_ids: RequestTracker::Current.enqueued_jobs.to_a.map { |ej| ej[:jid] }.compact,
          current_user: current_user_data(request)
        )
        req.location = headers["Location"] if headers.present?

        if error_payload.present?
          req.build_error_log(
            error_class: error_payload[:error_class].to_s,
            message: error_payload[:message],
            stack_trace: error_payload[:stack_trace]
          )
        end

        req.save!

        RequestTracker::Current.sent_mailers.to_a.each do |sm|
          RequestTracker::MailerLog.create!(request: req, status: "sent", **sm)
        end

        RequestTracker::Current.enqueued_mailers.to_a.each do |em|
          RequestTracker::MailerLog.create!(
            request: req,
            status: "enqueued",
            mailer_class: em[:mailer_class],
            action: em[:action],
            args: em[:args],
            queue: em[:queue],
            jid: em[:job_id]
          )
        end
      end
    rescue => e
      Rails.logger.warn("[request_tracker] failed to record request: #{e.class}: #{e.message}")
    end

    private

    # Reads whatever the router already stored in env during dispatch --
    # populated before the controller action runs (even if that action then
    # raises), and reflecting the real routing decision (auth constraints
    # around the mount included), not a synthetic re-recognition of the path.
    def request_tracker_route?(request)
      request.path_parameters[:controller].to_s.start_with?(ENGINE_CONTROLLER_PREFIX)
    end

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

      RequestTracker::BodyScrubber.scrub_headers(headers)
    end

    # Only JSON responses are captured -- anything else (HTML pages, file
    # downloads, streamed/live responses) is left completely untouched so
    # this can't break a response body that's only safe to read once.
    # Reading #each drains the original Rack body, so the app's actual
    # response has to be replaced with a fresh, replayable one wrapping the
    # buffered string.
    def capture_json_response_body(headers, response)
      content_type = headers && headers["Content-Type"]
      return [nil, response] if !content_type&.include?("json")

      buffer = +""
      response.each { |part| buffer << part }
      response.close if response.respond_to?(:close)

      [RequestTracker::BodyScrubber.scrub_body(buffer, content_type), [buffer]]
    end
  end
end
