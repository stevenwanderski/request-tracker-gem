require "net/http"

module Net
  class HTTP
    alias orig_request request unless method_defined?(:orig_request)

    def request(req, body = nil, &block)
      response = orig_request(req, body, &block)

      return response if !started?

      if !RequestTracker::Current.outbound_calls
        return response
      end

      request_body = RequestTracker::BodyScrubber.scrub_body(req.body, req['Content-Type'])
      response_body = RequestTracker::BodyScrubber.scrub_body(response.body, response['Content-Type'])

      RequestTracker::Current.outbound_calls << {
        url: "#{use_ssl? ? 'https' : 'http'}://#{address}#{req.path}",
        method: req.method,
        status: response.code.to_i,
        request_body: request_body,
        response_body: response_body
      }

      response
    end
  end
end
