# frozen_string_literal: true

class CreateTeams < ActiveRecord::Migration[7.1]
  def change
    create_table :teams, id: :uuid do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.integer :max_members, null: false
      t.references :owner, null: false, type: :uuid, foreign_key: { to_table: :users }

      t.timestamps
      t.datetime :deleted_at

      t.index :deleted_at
      t.index [:name, :owner_id], unique: true
    end

    create_table :team_members, id: :uuid do |t|
      t.references :team, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.column :role, :team_member_role, null: false, default: 'member'

      t.timestamps
      t.datetime :deleted_at

      t.index :deleted_at
      t.index [:team_id, :user_id], unique: true
    end
  end
end
