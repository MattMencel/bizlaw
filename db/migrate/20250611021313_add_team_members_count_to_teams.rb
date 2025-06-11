class AddTeamMembersCountToTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :team_members_count, :integer, default: 0, null: false

    # Backfill existing teams with current member count
    Team.find_each do |team|
      Team.reset_counters(team.id, :team_members)
    end
  end
end
