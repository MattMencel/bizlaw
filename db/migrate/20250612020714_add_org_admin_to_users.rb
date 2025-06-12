class AddOrgAdminToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :org_admin, :boolean, default: false, null: false
    add_index :users, [:organization_id, :org_admin], where: "org_admin = true"
  end
end
