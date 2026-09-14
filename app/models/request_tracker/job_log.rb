module RequestTracker
  class JobLog < ApplicationRecord
    # No FK to Request -- the request that enqueued this job only ever knows
    # the jid, and this row is written independently by the job's own
    # completion report, so jid is the only join key both sides agree on.
    def request
      RequestTracker::Request.where("job_ids @> ?", [jid].to_json).first
    end

    def mailer_logs
      RequestTracker::MailerLog.where(jid: jid)
    end
  end
end
