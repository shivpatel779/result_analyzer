class CreateTestResults < ActiveRecord::Migration[8.1]
  def change
    create_table :test_results do |t|
      t.string :student_name, null: false
      t.string :subject, null: false
      t.integer :marks, null: false
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_index :test_results, :recorded_at
    add_index :test_results, %i[subject recorded_at]
  end
end
