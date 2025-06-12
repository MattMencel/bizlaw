class CreateNegotiationRounds < ActiveRecord::Migration[8.0]
  def change
    create_enum :round_status, ["pending", "active", "plaintiff_submitted", "defendant_submitted", "both_submitted", "completed"]

    create_table :negotiation_rounds, id: :uuid do |t|
      t.references :simulation, null: false, foreign_key: true, type: :uuid
      t.integer :round_number, null: false
      t.enum :status, enum_type: "round_status", default: "pending", null: false
      t.datetime :deadline, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :negotiation_rounds, [:simulation_id, :round_number], unique: true
    add_index :negotiation_rounds, :status
    add_index :negotiation_rounds, :deadline
    add_index :negotiation_rounds, :deleted_at
  end
end
