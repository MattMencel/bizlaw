class CreateSimulations < ActiveRecord::Migration[8.0]
  def change
    create_enum :simulation_status, ["setup", "active", "paused", "completed", "arbitration"]
    create_enum :pressure_escalation, ["low", "moderate", "high"]

    create_table :simulations, id: :uuid do |t|
      t.references :case, null: false, foreign_key: true, type: :uuid
      t.datetime :start_date, null: false
      t.datetime :end_date
      t.integer :total_rounds, null: false, default: 6
      t.integer :current_round, null: false, default: 1
      t.enum :status, enum_type: "simulation_status", default: "setup", null: false
      t.decimal :plaintiff_min_acceptable, precision: 12, scale: 2, null: false
      t.decimal :plaintiff_ideal, precision: 12, scale: 2, null: false
      t.decimal :defendant_max_acceptable, precision: 12, scale: 2, null: false
      t.decimal :defendant_ideal, precision: 12, scale: 2, null: false
      t.enum :pressure_escalation_rate, enum_type: "pressure_escalation", default: "moderate", null: false
      t.jsonb :simulation_config, default: {}, null: false
      t.boolean :auto_events_enabled, default: true, null: false
      t.boolean :argument_quality_required, default: true, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :simulations, :status
    add_index :simulations, :start_date
    add_index :simulations, :current_round
    add_index :simulations, :deleted_at
  end
end
