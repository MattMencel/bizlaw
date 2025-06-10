class AddOrganizationToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :organization_id, :uuid, null: true
    add_index :users, :organization_id
    add_foreign_key :users, :organizations
  end
end
