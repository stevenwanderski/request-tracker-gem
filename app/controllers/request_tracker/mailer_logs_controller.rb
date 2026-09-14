module RequestTracker
  class MailerLogsController < ApplicationController
    include DateFilterable

    def index
      @mailer_logs = RequestTracker::MailerLog.all
      @mailer_logs = @mailer_logs.where(status: params[:status]) if params[:status].present?

      @mailer_logs = @mailer_logs.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
        .order(created_at: :desc)
        .page(params[:page])
    end

    def show
      @mailer_log = RequestTracker::MailerLog.find(params[:id])
    end
  end
end
