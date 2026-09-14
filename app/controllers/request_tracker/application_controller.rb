module RequestTracker
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    layout "request_tracker/application"
  end
end
