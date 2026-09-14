class CreateRequestTrackerSavedSearches < ActiveRecord::Migration[7.0]
  def change
    create_table :request_tracker_saved_searches do |t|
      t.string :name, null: false
      t.string :method
      t.string :status_code
      t.string :path
      t.string :outbound_call

      t.timestamps
    end

    add_index :request_tracker_saved_searches, :name, unique: true
  end
end
