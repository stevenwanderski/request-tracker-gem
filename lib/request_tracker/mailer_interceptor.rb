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
          body: RequestTracker::BodyScrubber.scrub_string(body)
        }
      elsif RequestTracker::Current.executing_job_id
        report(job_id: RequestTracker::Current.executing_job_id, message: message, body: body)
      end
    end

    def self.report(job_id:, message:, body:)
      RequestTracker::MailerLog.create!(
        jid: job_id,
        status: "sent",
        to: message.to,
        from: message.from,
        cc: message.cc,
        bcc: message.bcc,
        subject: message.subject,
        body: RequestTracker::BodyScrubber.scrub_string(body)
      )
    rescue => e
      Rails.logger.warn("[request_tracker] failed to record mailer log job_id=#{job_id}: #{e.class}: #{e.message}")
    end
  end
end
