class CreateSimulationEvents < ActiveRecord::Migration[8.0]
  def change
    create_enum :event_type, ["media_attention", "witness_change", "ipo_delay", "court_deadline", "additional_evidence", "expert_testimony"]

    create_table :simulation_events, id: :uuid do |t|
      t.references :simulation, null: false, foreign_key: true, type: :uuid
      t.enum :event_type, enum_type: "event_type", null: false
      t.jsonb :event_data, default: {}, null: false
      t.datetime :triggered_at, null: false
      t.text :impact_description, null: false
      t.jsonb :pressure_adjustment, default: {}, null: false
      t.integer :trigger_round, null: false
      t.boolean :automatic, default: true, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :simulation_events, :event_type
    add_index :simulation_events, :triggered_at
    add_index :simulation_events, :trigger_round
    add_index :simulation_events, :deleted_at
  end
end
