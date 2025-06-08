# frozen_string_literal: true

class CreateCaseEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :case_events, id: :uuid do |t|
      t.references :case, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :event_type, null: false
      t.jsonb :data, null: false, default: {}
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :case_events, :event_type
    add_index :case_events, :deleted_at
  end
end
