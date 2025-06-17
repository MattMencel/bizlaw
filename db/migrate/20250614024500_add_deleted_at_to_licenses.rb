class AddDeletedAtToLicenses < ActiveRecord::Migration[8.0]
  def change
    add_column :licenses, :deleted_at, :datetime
  end
end
