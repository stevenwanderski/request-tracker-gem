module RequestTracker
  class ErrorLog < ApplicationRecord
    belongs_to :request

    scope :visible, -> { where(hidden_at: nil) }
    scope :hidden, -> { where.not(hidden_at: nil) }

    before_create :apply_hidden_error_class_mute

    private

    # Muting an error class hides not just its existing occurrences (handled
    # separately, in bulk, when the mute is created) but every future one too
    # -- checked here, at creation time, against the single install-wide mute
    # list.
    def apply_hidden_error_class_mute
      return if hidden_at?

      self.hidden_at = Time.current if RequestTracker::HiddenErrorClass.exists?(error_class: error_class)
    end
  end
end
