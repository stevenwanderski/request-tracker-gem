class CreateRequestTrackerErrorLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :request_tracker_error_logs do |t|
      t.references :request, null: false, foreign_key: { to_table: :request_tracker_requests }
      t.string :error_class
      t.string :message
      t.jsonb :stack_trace
      t.datetime :hidden_at

      t.timestamps
    end

    add_index :request_tracker_error_logs, :hidden_at
  end
end
