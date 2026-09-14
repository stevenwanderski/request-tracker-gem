module RequestTracker
  module DateFilterable
    extend ActiveSupport::Concern

    included do
      before_action :set_date_filters
    end

    private

    def set_date_filters
      @start_date = parse_date(params[:start_date]) || 30.days.ago.to_date
      @end_date = parse_date(params[:end_date]) || Date.current
    end

    def parse_date(value)
      Date.parse(value) if value.present?
    end
  end
end
