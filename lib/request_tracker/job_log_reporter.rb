module RequestTracker
  class JobLogReporter
    def self.report(jid:, status:, started_at:, completed_at:, error: nil)
      payload = {
        jid: jid,
        app_id: ENV["REQUEST_TRACKER_APP_ID"],
        status: status,
        started_at: started_at,
        completed_at: completed_at,
        api_token: ENV["REQUEST_TRACKER_API_TOKEN"]
      }
      payload[:error] = error if error

      Thread.new(payload) do |payload|
        post_with_retry(payload)
      end
    end

    # The originating request's own /requests POST (which is what actually creates
    # the JobLog row) only fires after that whole request finishes rendering, in its
    # own background thread. A fast job can start, run, and report completion before
    # that row exists yet, so a 404 here doesn't mean failure -- it means "not yet".
    # Retry briefly rather than dropping the report.
    def self.post_with_retry(payload, attempts: 5, delay: 0.5)
      attempts.times do |i|
        begin
          response = Net::HTTP.post(
            URI(job_logs_api_url),
            payload.to_json,
            "Content-Type" => "application/json"
          )

          return if response.is_a?(Net::HTTPSuccess)

          if response.code == "404" && i < attempts - 1
            sleep delay
            next
          end

          warn "[request_tracker] POST /job_logs rejected: #{response.code} #{response.body}"
          return
        rescue => e
          warn "[request_tracker] Background POST /job_logs failed: #{e.class}: #{e.message}"
          return
        end
      end
    end

    def self.job_logs_api_url
      requests_url = ENV.fetch("REQUEST_TRACKER_API_URL", RequestTracker::Middleware::DEFAULT_API_URL)
      requests_url.sub(%r{/requests\z}, "/job_logs")
    end
  end
end
