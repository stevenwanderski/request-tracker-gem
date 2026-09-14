module RequestTracker
  class JobLogsController < ApplicationController
    include DateFilterable

    def index
      @job_logs = RequestTracker::JobLog
        .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
        .order(created_at: :desc)
        .page(params[:page])
    end

    def show
      @job_log = RequestTracker::JobLog.find(params[:id])
    end
  end
end
