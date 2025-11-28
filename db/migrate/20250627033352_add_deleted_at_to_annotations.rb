class AddDeletedAtToAnnotations < ActiveRecord::Migration[8.0]
  def change
    add_column :annotations, :deleted_at, :datetime
    add_index :annotations, :deleted_at
  end
end
