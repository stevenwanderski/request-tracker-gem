module RequestTracker
  class ErrorLogsController < ApplicationController
    include DateFilterable

    def index
      @hidden = params[:hidden].present?

      if @hidden
        @hidden_error_classes = RequestTracker::HiddenErrorClass.order(created_at: :desc)
        @hidden_counts_by_class = RequestTracker::ErrorLog.hidden.group(:error_class).count
      else
        @error_logs = RequestTracker::ErrorLog.visible
          .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
          .order(created_at: :desc)
          .page(params[:page])
      end

      @hidden_class_count = RequestTracker::HiddenErrorClass.count
    end

    def show
      @error_log = RequestTracker::ErrorLog.find(params[:id])
      @muted = RequestTracker::HiddenErrorClass.exists?(error_class: @error_log.error_class)
    end

    def hide
      RequestTracker::HiddenErrorClass.find_or_create_by!(error_class: params[:error_class])

      RequestTracker::ErrorLog.visible.where(error_class: params[:error_class]).update_all(hidden_at: Time.current)

      redirect_back fallback_location: error_logs_path
    end

    def unhide
      RequestTracker::HiddenErrorClass.where(error_class: params[:error_class]).destroy_all

      RequestTracker::ErrorLog.hidden.where(error_class: params[:error_class]).update_all(hidden_at: nil)

      redirect_back fallback_location: error_logs_path(hidden: true)
    end
  end
end
