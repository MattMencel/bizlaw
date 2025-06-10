class CreateOrganizations < ActiveRecord::Migration[8.0]
  def change
    create_table :organizations, id: :uuid do |t|
      t.string :name, null: false
      t.string :domain, null: false
      t.string :slug, null: false
      t.text :description
      t.boolean :active, default: true, null: false
      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_index :organizations, :slug, unique: true
    add_index :organizations, :domain, unique: true
    add_index :organizations, :active
    add_index :organizations, :deleted_at
  end
end
