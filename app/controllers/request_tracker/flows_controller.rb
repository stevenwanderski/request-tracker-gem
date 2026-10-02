module RequestTracker
  class FlowsController < ApplicationController
    # A long-lived session can rack up thousands of requests; the journey view
    # is for reading a visit, not paging an archive, so it shows the most
    # recent slice and says so.
    STEP_LIMIT = 500

    # A pause this long between two requests almost always means the visitor
    # left and came back, so the timeline breaks into a new visit there.
    VISIT_GAP = 30.minutes

    def show
      @flow_id = params[:id]

      scope = RequestTracker::Request.where(flow_id: @flow_id)
      @total_count = scope.count
      raise ActiveRecord::RecordNotFound if @total_count.zero?

      @requests = scope.includes(:error_log).order(created_at: :desc).limit(STEP_LIMIT).to_a.reverse

      # Jobs and mailers are joined by jid rather than FK (see Request#job_logs),
      # so load them for the whole flow in two queries instead of two per step.
      job_ids = @requests.flat_map(&:job_ids)
      @job_logs_by_jid = RequestTracker::JobLog.where(jid: job_ids).index_by(&:jid)
      mailer_logs = RequestTracker::MailerLog.where(request_id: @requests.map(&:id)).or(RequestTracker::MailerLog.where(jid: job_ids)).to_a
      @mailer_logs_by_request_id = @requests.to_h do |req|
        [req.id, mailer_logs.select { |ml| ml.request_id == req.id || req.job_ids.include?(ml.jid) }]
      end

      @visits = @requests.slice_when { |a, b| b.created_at - a.created_at > VISIT_GAP }.to_a
    end
  end
end
