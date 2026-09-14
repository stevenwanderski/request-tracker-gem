module RequestTracker
  class JobLogReporter
    def self.report(jid:, worker_class:, queue:, args:, status:, started_at:, completed_at:, outbound_calls: nil, error: nil)
      RequestTracker::JobLog.create!(
        jid: jid,
        worker_class: worker_class,
        queue: queue,
        args: RequestTracker::BodyScrubber.scrub_json(args),
        status: status,
        started_at: started_at,
        completed_at: completed_at,
        outbound_calls: outbound_calls,
        error_class: error && error[:error_class],
        error_message: error && error[:message],
        error_backtrace: error && error[:backtrace]
      )
    rescue => e
      Rails.logger.warn("[request_tracker] failed to record job log jid=#{jid}: #{e.class}: #{e.message}")
    end
  end
end
