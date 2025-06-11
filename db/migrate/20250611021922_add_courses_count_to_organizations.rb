class AddCoursesCountToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :courses_count, :integer, default: 0, null: false

    # Update existing records with current count
    reversible do |dir|
      dir.up do
        Organization.find_each do |organization|
          Organization.reset_counters(organization.id, :courses)
        end
      end
    end
  end
end
