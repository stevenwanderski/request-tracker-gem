class CreateRequestTrackerHiddenErrorClasses < ActiveRecord::Migration[7.0]
  def change
    create_table :request_tracker_hidden_error_classes do |t|
      t.string :error_class, null: false

      t.timestamps
    end

    add_index :request_tracker_hidden_error_classes, :error_class, unique: true
  end
end
