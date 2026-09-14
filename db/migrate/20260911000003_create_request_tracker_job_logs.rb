class CreateRequestTrackerJobLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :request_tracker_job_logs do |t|
      t.string :jid
      t.string :worker_class
      t.string :queue
      t.jsonb :args
      t.string :status
      t.datetime :started_at
      t.datetime :completed_at
      t.jsonb :outbound_calls
      t.string :error_class
      t.string :error_message
      t.jsonb :error_backtrace

      t.timestamps
    end

    add_index :request_tracker_job_logs, :jid
  end
end
