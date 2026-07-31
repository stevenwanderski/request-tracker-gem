module RequestTracker
  class Current < ActiveSupport::CurrentAttributes
    attribute :outbound_calls
    attribute :enqueued_jobs
    attribute :sent_mailers
    attribute :enqueued_mailers
    attribute :executing_job_id
  end
end