class CreateCourseEnrollments < ActiveRecord::Migration[8.0]
  def change
    create_table :course_enrollments, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.uuid :course_id, null: false
      t.datetime :enrolled_at, null: false
      t.string :status, default: 'active', null: false
      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_index :course_enrollments, :user_id
    add_index :course_enrollments, :course_id
    add_index :course_enrollments, [:user_id, :course_id], unique: true
    add_index :course_enrollments, :status
    add_index :course_enrollments, :enrolled_at
    add_index :course_enrollments, :deleted_at

    add_foreign_key :course_enrollments, :users
    add_foreign_key :course_enrollments, :courses
  end
end
