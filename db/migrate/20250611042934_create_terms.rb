class CreateTerms < ActiveRecord::Migration[8.0]
  def change
    create_table :terms, id: :uuid do |t|
      t.string :term_name, null: false
      t.integer :academic_year, null: false
      t.string :slug, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.text :description
      t.uuid :organization_id, null: false
      t.boolean :active, default: true, null: false
      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_index :terms, :organization_id
    add_index :terms, :academic_year
    add_index :terms, :active
    add_index :terms, :deleted_at
    add_index :terms, [:organization_id, :slug], unique: true
    add_index :terms, [:organization_id, :academic_year, :active]
    add_index :terms, [:start_date, :end_date]

    add_foreign_key :terms, :organizations
  end
end
