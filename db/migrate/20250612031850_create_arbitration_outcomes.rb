class CreateArbitrationOutcomes < ActiveRecord::Migration[8.0]
  def change
    create_enum :outcome_type, ["plaintiff_victory", "defendant_victory", "split_decision", "no_award"]

    create_table :arbitration_outcomes, id: :uuid do |t|
      t.references :simulation, null: false, foreign_key: true, type: :uuid
      t.decimal :award_amount, precision: 12, scale: 2, null: false
      t.text :rationale, null: false
      t.jsonb :factors_considered, default: {}, null: false
      t.datetime :calculated_at, null: false
      t.enum :outcome_type, enum_type: "outcome_type", null: false
      t.decimal :evidence_strength_factor, precision: 5, scale: 2
      t.decimal :argument_quality_factor, precision: 5, scale: 2
      t.decimal :negotiation_history_factor, precision: 5, scale: 2
      t.decimal :random_variance, precision: 5, scale: 2
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :arbitration_outcomes, :outcome_type
    add_index :arbitration_outcomes, :award_amount
    add_index :arbitration_outcomes, :calculated_at
    add_index :arbitration_outcomes, :deleted_at
  end
end
