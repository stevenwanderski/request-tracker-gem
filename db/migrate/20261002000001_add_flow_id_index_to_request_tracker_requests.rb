class AddFlowIdIndexToRequestTrackerRequests < ActiveRecord::Migration[7.0]
  def change
    add_index :request_tracker_requests, [:flow_id, :created_at]
  end
end
