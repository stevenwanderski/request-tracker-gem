module RequestTracker
  class MailerLog < ApplicationRecord
    belongs_to :request, optional: true

    # Mailers built during a request always know their request_id immediately.
    # Mailers sent from within a background job only ever have a jid, so they
    # have to be resolved live via jsonb containment against Request#job_ids.
    def request
      super || (jid.present? ? RequestTracker::Request.where("job_ids @> ?", [jid].to_json).first : nil)
    end

    def job_log
      RequestTracker::JobLog.find_by(jid: jid)
    end
  end
end
