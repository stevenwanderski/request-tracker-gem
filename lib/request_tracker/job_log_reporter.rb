module RequestTracker
  class JobLogReporter
    def self.report(jid:, worker_class:, queue:, args:, status:, started_at:, completed_at:, outbound_calls: nil, error: nil)
      payload = {
        jid: jid,
        app_id: ENV["REQUEST_TRACKER_APP_ID"],
        worker_class: worker_class,
        queue: queue,
        args: args,
        status: status,
        started_at: started_at,
        completed_at: completed_at,
        outbound_calls: outbound_calls,
        api_token: ENV["REQUEST_TRACKER_API_TOKEN"]
      }
      payload[:error] = error if error

      Thread.new(payload) do |payload|
        begin
          response = Net::HTTP.post(
            URI(job_logs_api_url),
            payload.to_json,
            "Content-Type" => "application/json"
          )
          warn "[request_tracker] POST /job_logs rejected: #{response.code} #{response.body}" if !response.is_a?(Net::HTTPSuccess)
        rescue => e
          warn "[request_tracker] Background POST /job_logs failed: #{e.class}: #{e.message}"
        end
      end
    end

    def self.job_logs_api_url
      requests_url = ENV.fetch("REQUEST_TRACKER_API_URL", RequestTracker::Middleware::DEFAULT_API_URL)
      requests_url.sub(%r{/requests\z}, "/job_logs")
    end
  end
end
