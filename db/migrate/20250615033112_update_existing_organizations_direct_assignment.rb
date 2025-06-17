class UpdateExistingOrganizationsDirectAssignment < ActiveRecord::Migration[8.0]
  def up
    # Update any existing organizations that have null direct_assignment_enabled to true
    execute <<-SQL
      UPDATE organizations 
      SET direct_assignment_enabled = true 
      WHERE direct_assignment_enabled IS NULL;
    SQL
  end

  def down
    # Intentionally left blank - we don't want to revert this change
  end
end
