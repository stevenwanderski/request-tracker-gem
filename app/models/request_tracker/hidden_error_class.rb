module RequestTracker
  class HiddenErrorClass < ApplicationRecord
    validates :error_class, presence: true, uniqueness: true
  end
end
