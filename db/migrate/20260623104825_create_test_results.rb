class CreateTestResults < ActiveRecord::Migration[8.1]
  def change
    create_table :test_results do |t|
      t.string :student_name
      t.string :subject
      t.integer :marks
      t.datetime :timestamp

      t.timestamps
    end
  end
end
