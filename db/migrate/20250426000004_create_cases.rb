# frozen_string_literal: true

class CreateCases < ActiveRecord::Migration[7.1]
  def change
    create_table :cases, id: :uuid do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.string :reference_number, null: false
      t.column :status, :case_status, null: false, default: 'not_started'
      t.column :difficulty_level, :case_difficulty, null: false
      t.column :case_type, :case_type, null: false
      t.jsonb :plaintiff_info, null: false, default: {}
      t.jsonb :defendant_info, null: false, default: {}
      t.jsonb :legal_issues, null: false, default: []
      t.datetime :due_date
      t.datetime :published_at
      t.datetime :archived_at
      t.references :team, null: false, type: :uuid, foreign_key: true
      t.references :created_by, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.references :updated_by, null: false, type: :uuid, foreign_key: { to_table: :users }

      t.timestamps
      t.datetime :deleted_at

      t.index :reference_number, unique: true
      t.index :deleted_at
      t.index :status
      t.index :difficulty_level
      t.index :case_type
    end

    create_table :case_events, id: :uuid do |t|
      t.references :case, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :event_type, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
      t.datetime :deleted_at

      t.index :deleted_at
      t.index :event_type
    end
  end
end
