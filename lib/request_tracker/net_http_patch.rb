module Net
  class HTTP
    alias orig_request request unless method_defined?(:orig_request)

    def request(req, body = nil, &block)
      response = orig_request(req, body, &block)

      return response if !started?

      if !RequestTracker::Current.outbound_calls
        return response
      end

      request_is_json = req['Content-Type']&.include?('application/json')
      response_is_json = response['Content-Type']&.include?('application/json')

      request_body = request_is_json ? JSON.parse(body || req.body) : body || req.body
      response_body = response_is_json ? JSON.parse(response.body) : response.body

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
