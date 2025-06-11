# frozen_string_literal: true

class CreateLicenses < ActiveRecord::Migration[8.0]
  def change
    create_table :licenses, id: :uuid do |t|
      t.string :license_key, null: false, index: { unique: true }
      t.string :organization_name, null: false
      t.string :contact_email, null: false
      t.string :license_type, null: false, default: 'free'
      t.integer :max_instructors, default: 1
      t.integer :max_students, default: 3
      t.integer :max_courses, default: 1
      t.date :expires_at
      t.text :signature, null: false
      t.jsonb :features, default: {}
      t.boolean :active, default: true
      t.datetime :last_validated_at
      t.string :validation_hash
      t.text :notes

      t.timestamps
    end

    add_index :licenses, :license_type
    add_index :licenses, :expires_at
    add_index :licenses, :active
    add_index :licenses, :organization_name
  end
end
