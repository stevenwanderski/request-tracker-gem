module RequestTracker
  class MailerInterceptor
    def self.delivering_email(message)
      return if !RequestTracker.config.enabled_environments.include?(Rails.env)

      body = message.html_part ? message.html_part.body.decoded : message.body.decoded

      if RequestTracker::Current.sent_mailers
        RequestTracker::Current.sent_mailers << {
          to: message.to,
          from: message.from,
          cc: message.cc,
          bcc: message.bcc,
          subject: message.subject,
          body: body
        }
      elsif RequestTracker::Current.executing_job_id
        report(job_id: RequestTracker::Current.executing_job_id, message: message, body: body)
      end
    end

    def self.report(job_id:, message:, body:)
      payload = {
        job_id: job_id,
        app_id: ENV["REQUEST_TRACKER_APP_ID"],
        to: message.to,
        from: message.from,
        cc: message.cc,
        bcc: message.bcc,
        subject: message.subject,
        body: body,
        api_token: ENV["REQUEST_TRACKER_API_TOKEN"]
      }

      Thread.new(payload) do |payload|
        api_url = mailer_api_url

        begin
          response = Net::HTTP.post(
            URI(api_url),
            payload.to_json,
            "Content-Type" => "application/json"
          )
          warn "[request_tracker] POST /mailers rejected: #{response.code} #{response.body}" if !response.is_a?(Net::HTTPSuccess)
        rescue => e
          warn "[request_tracker] Background POST /mailers failed: #{e.class}: #{e.message}"
        end
      end
    end

    def self.mailer_api_url
      requests_url = ENV.fetch("REQUEST_TRACKER_API_URL", RequestTracker::Middleware::DEFAULT_API_URL)
      requests_url.sub(%r{/requests\z}, "/mailers")
    end
  end
end
