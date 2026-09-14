module RequestTracker
  class RequestsController < ApplicationController
    include DateFilterable

    def index
      @saved_searches = RequestTracker::SavedSearch.order(:name)

      @requests = RequestTracker::Request.all
      @requests = @requests.where(method: params[:method]) if params[:method].present?
      @requests = @requests.where(status_code: params[:status]) if params[:status].present?
      @requests = @requests.where("path ILIKE ?", "%#{params[:path]}%") if params[:path].present?

      if params[:outbound_call].present?
        @requests = @requests.where(
          "EXISTS (SELECT 1 FROM jsonb_array_elements(outbound_calls) AS call WHERE call ->> 'url' ILIKE ?)",
          "%#{params[:outbound_call]}%"
        )
      end

      @requests = @requests.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
        .order(created_at: :desc)
        .page(params[:page])
    end

    def grouped
      @requests = RequestTracker::Request
        .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
        .select("path, COUNT(*) AS count")
        .group(:path)
        .order("count DESC")
        .page(params[:page])
    end

    def show
      @request = RequestTracker::Request.find(params[:id])
    end
  end
end
