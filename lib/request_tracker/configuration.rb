module RequestTracker
  class Configuration
    attr_accessor :enabled_environments

    # A callable that receives the ActionDispatch::Request and returns
    # whatever should represent the current user for that request -- an ID,
    # an email, or the whole user object. Left unset, no user is recorded.
    # Set it in an initializer:
    #
    #   RequestTracker.configure do |config|
    #     config.current_user = ->(request) { request.env["warden"]&.user }
    #   end
    attr_accessor :current_user

    def initialize
      @enabled_environments = []
      @current_user = nil
    end
  end
end
