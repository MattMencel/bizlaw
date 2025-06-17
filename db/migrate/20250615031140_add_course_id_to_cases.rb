class AddCourseIdToCases < ActiveRecord::Migration[8.0]
  def change
    # Add course_id column with UUID type
    add_column :cases, :course_id, :uuid
    add_index :cases, :course_id
    add_foreign_key :cases, :courses
    
    # Migrate data: set course_id based on team's course
    # This assumes teams have course_id (which they do)
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE cases 
          SET course_id = teams.course_id 
          FROM teams 
          WHERE cases.team_id = teams.id
        SQL
        
        # Now make course_id not null
        change_column_null :cases, :course_id, false
        
        # Remove team_id column since cases now belong to courses
        remove_column :cases, :team_id
      end
      
      dir.down do
        # Add team_id back
        add_column :cases, :team_id, :uuid, null: false
        add_index :cases, :team_id
        add_foreign_key :cases, :teams
        
        # This down migration would need manual intervention to assign teams
        # since one case can have multiple teams assigned via case_teams
        
        # Remove course_id
        remove_column :cases, :course_id
      end
    end
  end
end
