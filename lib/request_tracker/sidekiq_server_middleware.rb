module RequestTracker
  class SidekiqServerMiddleware
    def call(_worker, job, _queue)
      if !RequestTracker.config.enabled_environments.include?(Rails.env)
        return yield
      end

      RequestTracker::Current.executing_job_id = job["jid"]

      yield
    ensure
      RequestTracker::Current.executing_job_id = nil
    end
  end
end
