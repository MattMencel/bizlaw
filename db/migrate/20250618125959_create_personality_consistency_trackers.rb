class CreatePersonalityConsistencyTrackers < ActiveRecord::Migration[8.0]
  def change
    create_table :personality_consistency_trackers, id: :uuid do |t|
      t.references :case, null: false, foreign_key: true, type: :uuid
      t.string :personality_type, null: false
      t.jsonb :response_history, default: [], null: false
      t.integer :consistency_score, null: false

      t.datetime :deleted_at
      t.timestamps

      t.index [:case_id, :personality_type], name: 'index_personality_trackers_on_case_and_type'
      t.index :personality_type
      t.index :consistency_score
      t.index :deleted_at
    end
  end
end
