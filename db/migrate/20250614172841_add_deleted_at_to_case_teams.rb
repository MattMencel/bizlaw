class AddDeletedAtToCaseTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :case_teams, :deleted_at, :datetime
    add_index :case_teams, :deleted_at
  end
end
