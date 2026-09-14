module RequestTracker
  class SavedSearch < ApplicationRecord
    validates :name, presence: true, uniqueness: true
  end
end
