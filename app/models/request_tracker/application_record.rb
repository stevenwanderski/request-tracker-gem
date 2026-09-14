module RequestTracker
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    self.table_name_prefix = "request_tracker_"
  end
end
