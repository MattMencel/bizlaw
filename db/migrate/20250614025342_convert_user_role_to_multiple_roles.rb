class ConvertUserRoleToMultipleRoles < ActiveRecord::Migration[8.0]
  def up
    # Add new roles array column
    add_column :users, :roles, :text, array: true, default: []
    
    # Migrate existing role and org_admin data to roles array
    User.reset_column_information
    User.find_each do |user|
      roles = [user.role]
      roles << 'org_admin' if user.org_admin?
      user.update_column(:roles, roles)
    end
    
    # Add index for the new roles array
    add_index :users, :roles, using: :gin
    
    # Remove old columns (we'll keep them for now in case we need to rollback)
    # remove_column :users, :role
    # remove_column :users, :org_admin
  end
  
  def down
    # This would restore the old structure if needed
    # add_column :users, :role, :enum, enum_type: "user_role", default: "student", null: false
    # add_column :users, :org_admin, :boolean, default: false, null: false
    
    # Migrate roles array back to individual columns
    User.reset_column_information
    User.find_each do |user|
      primary_role = (user.roles & ['student', 'instructor', 'admin']).first || 'student'
      is_org_admin = user.roles.include?('org_admin')
      
      user.update_columns(
        role: primary_role,
        org_admin: is_org_admin
      )
    end
    
    remove_index :users, :roles
    remove_column :users, :roles
  end
end
