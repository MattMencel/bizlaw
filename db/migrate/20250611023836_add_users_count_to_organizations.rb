class AddUsersCountToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :users_count, :integer, default: 0, null: false

    # Backfill existing organizations with current user count
    Organization.find_each do |organization|
      Organization.reset_counters(organization.id, :users)
    end
  end
end
