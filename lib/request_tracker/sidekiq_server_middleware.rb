module RequestTracker
  class SidekiqServerMiddleware
    def call(_worker, job, _queue)
      if !RequestTracker.config.enabled_environments.include?(Rails.env)
        return yield
      end

      RequestTracker::Current.executing_job_id = job["jid"]
      started_at = Time.current

      begin
        yield
        report_completion(job, started_at, status: "completed")
      rescue => e
        report_completion(job, started_at, status: "failed", error: e)
        raise
      end
    ensure
      RequestTracker::Current.executing_job_id = nil
    end

    private

    def report_completion(job, started_at, status:, error: nil)
      RequestTracker::JobLogReporter.report(
        jid: job["jid"],
        status: status,
        started_at: started_at,
        completed_at: Time.current,
        error: error && {
          error_class: error.class.name,
          message: error.message,
          backtrace: error.backtrace
        }
      )
    end
  end
end
