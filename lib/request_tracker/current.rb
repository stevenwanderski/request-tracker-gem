module RequestTracker
  class Current < ActiveSupport::CurrentAttributes
    attribute :outbound_calls
    attribute :enqueued_jobs
  end
end