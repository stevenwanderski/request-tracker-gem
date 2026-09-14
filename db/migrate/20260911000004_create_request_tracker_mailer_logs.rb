class CreateRequestTrackerMailerLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :request_tracker_mailer_logs do |t|
      t.references :request, null: true, foreign_key: { to_table: :request_tracker_requests }
      t.string :jid
      t.string :status
      t.string :mailer_class
      t.string :action
      t.string :queue
      t.jsonb :args
      t.jsonb :to
      t.jsonb :from
      t.jsonb :cc
      t.jsonb :bcc
      t.string :subject
      t.text :body

      t.timestamps
    end

    add_index :request_tracker_mailer_logs, :jid
  end
end
