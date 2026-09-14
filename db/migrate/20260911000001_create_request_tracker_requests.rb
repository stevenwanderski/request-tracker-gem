class CreateRequestTrackerRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :request_tracker_requests do |t|
      t.string :flow_id
      t.string :referer
      t.string :path
      t.string :method
      t.string :status_code
      t.string :location
      t.string :user_agent
      t.jsonb :request_body
      t.jsonb :response_body
      t.jsonb :headers
      t.jsonb :outbound_calls
      t.jsonb :current_user
      t.jsonb :job_ids, default: [], null: false

      t.timestamps
    end

    add_index :request_tracker_requests, :job_ids, using: :gin
  end
end
