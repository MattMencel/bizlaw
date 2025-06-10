class AddCourseToTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :course_id, :uuid, null: true
    add_index :teams, :course_id
    add_foreign_key :teams, :courses
  end
end
