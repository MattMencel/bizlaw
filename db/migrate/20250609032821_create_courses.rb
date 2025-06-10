class CreateCourses < ActiveRecord::Migration[8.0]
  def change
    create_table :courses, id: :uuid do |t|
      t.string :title, null: false
      t.text :description
      t.uuid :instructor_id, null: false
      t.string :course_code, null: false
      t.string :semester
      t.integer :year
      t.date :start_date
      t.date :end_date
      t.boolean :active, default: true, null: false
      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_index :courses, :instructor_id
    add_index :courses, :course_code, unique: true
    add_index :courses, :active
    add_index :courses, :deleted_at
    add_index :courses, [:year, :semester]

    add_foreign_key :courses, :users, column: :instructor_id
  end
end
