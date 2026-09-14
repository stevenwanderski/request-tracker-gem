module RequestTracker
  class Request < ApplicationRecord
    has_one :error_log

    # Order matters: Edge, Opera, and Samsung Internet all include "Chrome" (or
    # "Safari") in their user agent for site-compatibility reasons, so the more
    # specific matches have to run before the generic ones. Parsed from the raw
    # header on read rather than at capture time, so improving this list
    # reclassifies every request ever stored instead of only new ones.
    BROWSER_PATTERNS = [
      [/EdgiOS|EdgA|Edg\//, "Edge"],
      [/OPR\/|OPiOS/, "Opera"],
      [/SamsungBrowser/, "Samsung Internet"],
      [/FxiOS|Firefox/, "Firefox"],
      [/CriOS|Chrome|Chromium/, "Chrome"],
      [/Mobile.*Safari|iPhone|iPad/, "Mobile Safari"],
      [/Safari/, "Safari"]
    ].freeze

    def browser
      return nil if user_agent.blank?

      _, name = BROWSER_PATTERNS.find { |pattern, _| user_agent.match?(pattern) }
      name
    end

    # A JobLog is created solely by the job's own completion report, which has no
    # way to know request_id at write time -- so there's no FK to join through.
    # jid is the only thing both sides agree on, so that's the join key.
    def job_logs
      RequestTracker::JobLog.where(jid: job_ids)
    end

    # Mailers built during this request (deliver_now/deliver_later called directly
    # in the controller) always know their request_id immediately -- no race there.
    # Mailers sent from within a background job report separately and are only
    # ever findable by jid.
    def mailer_logs
      RequestTracker::MailerLog.where(request_id: id).or(RequestTracker::MailerLog.where(jid: job_ids))
    end
  end
end
