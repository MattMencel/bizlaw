class AddOrganizationToCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :organization_id, :uuid, null: true
    add_index :courses, :organization_id
    add_foreign_key :courses, :organizations

    # Update unique constraint for course_code to be scoped by organization
    remove_index :courses, :course_code
    add_index :courses, [:course_code, :organization_id], unique: true
  end
end
