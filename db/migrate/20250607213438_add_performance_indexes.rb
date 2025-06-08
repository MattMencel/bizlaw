class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Add indexes for frequently queried timestamp columns
    add_index :cases, :created_at, name: "index_cases_on_created_at"
    add_index :case_events, :created_at, name: "index_case_events_on_created_at"
    add_index :team_members, :created_at, name: "index_team_members_on_created_at"
    add_index :documents, :created_at, name: "index_documents_on_created_at"

    # Add composite indexes for common queries
    add_index :team_members, [:user_id, :team_id],
              where: "deleted_at IS NULL",
              name: "index_team_members_active_user_team"

    # Add index for case search by title (partial match)
    add_index :cases, "LOWER(title)", name: "index_cases_on_lower_title"

    # Add index for user search by name
    add_index :users, "LOWER(first_name), LOWER(last_name)",
              name: "index_users_on_lower_names"

    # Add composite index for case filtering
    add_index :cases, [:status, :difficulty_level, :case_type],
              name: "index_cases_on_status_difficulty_type"

    # Add index for soft-deleted records queries
    add_index :cases, [:deleted_at, :created_at],
              name: "index_cases_on_deleted_at_created_at"
    add_index :team_members, [:deleted_at, :user_id, :team_id],
              name: "index_team_members_on_deleted_at_user_team"
  end
end
