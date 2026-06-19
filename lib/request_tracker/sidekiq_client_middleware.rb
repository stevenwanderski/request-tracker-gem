module RequestTracker
  class SidekiqClientMiddleware
    def call(worker_class, job, queue, _redis_pool)
      return yield if !RequestTracker::Current.enqueued_jobs

      RequestTracker::Current.enqueued_jobs << {
        class: worker_class,
        args: job["args"],
        queue: queue,
        jid: job["jid"]
      }

      yield
    end
  end
end