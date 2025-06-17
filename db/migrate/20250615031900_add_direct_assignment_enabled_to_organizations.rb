class AddDirectAssignmentEnabledToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :direct_assignment_enabled, :boolean, default: true, null: false
    add_index :organizations, :direct_assignment_enabled
  end
end
