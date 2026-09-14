module RequestTracker
  class SavedSearchesController < ApplicationController
    def create
      @saved_search = RequestTracker::SavedSearch.new(saved_search_params)

      if @saved_search.save
        redirect_to requests_path(request_filter_params), notice: "Search saved."
      else
        redirect_to requests_path(request_filter_params), alert: @saved_search.errors.full_messages.to_sentence
      end
    end

    def destroy
      @saved_search = RequestTracker::SavedSearch.find(params[:id])
      @saved_search.destroy!

      redirect_to requests_path, notice: "Search deleted."
    end

    private

    def saved_search_params
      params.permit(:name, :path, :method, :status, :outbound_call)
        .to_h
        .transform_keys { |key| key == "status" ? "status_code" : key }
    end

    def request_filter_params
      params.permit(:path, :method, :status, :outbound_call)
    end
  end
end
