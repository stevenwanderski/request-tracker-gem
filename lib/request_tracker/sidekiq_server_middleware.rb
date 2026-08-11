module RequestTracker
  class SidekiqServerMiddleware
    def call(_worker, job, queue)
      if !RequestTracker.config.enabled_environments.include?(Rails.env)
        return yield
      end

      RequestTracker::Current.executing_job_id = job["jid"]
      RequestTracker::Current.outbound_calls = []
      started_at = Time.current

      begin
        yield
        report_completion(job, queue, started_at, status: "completed")
      rescue => e
        report_completion(job, queue, started_at, status: "failed", error: e)
        raise
      end
    ensure
      RequestTracker::Current.executing_job_id = nil
      RequestTracker::Current.outbound_calls = nil
    end

    private

    # JobLog is created entirely from this report -- there's no separate
    # enqueue-time record anymore -- so worker_class/queue/args have to travel
    # with it; nothing else will ever supply them.
    def report_completion(job, queue, started_at, status:, error: nil)
      RequestTracker::JobLogReporter.report(
        jid: job["jid"],
        worker_class: job["class"],
        queue: queue,
        args: job["args"],
        status: status,
        started_at: started_at,
        completed_at: Time.current,
        outbound_calls: RequestTracker::Current.outbound_calls,
        error: error && {
          error_class: error.class.name,
          message: error.message,
          backtrace: RequestTracker::BacktraceContext.build(error)
        }
      )
    end
  end
end
