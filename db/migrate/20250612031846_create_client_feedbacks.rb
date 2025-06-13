class CreateClientFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_enum :feedback_type, ["offer_reaction", "strategy_guidance", "pressure_response", "settlement_satisfaction"]
    create_enum :mood_level, ["very_unhappy", "unhappy", "neutral", "satisfied", "very_satisfied"]

    create_table :client_feedbacks, id: :uuid do |t|
      t.references :simulation, null: false, foreign_key: true, type: :uuid
      t.references :team, null: false, foreign_key: true, type: :uuid
      t.enum :feedback_type, enum_type: "feedback_type", null: false
      t.enum :mood_level, enum_type: "mood_level", null: false
      t.decimal :satisfaction_score, precision: 5, scale: 2, null: false
      t.text :feedback_text, null: false
      t.integer :triggered_by_round, null: false
      t.references :settlement_offer, null: true, foreign_key: true, type: :uuid
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :client_feedbacks, :feedback_type
    add_index :client_feedbacks, :mood_level
    add_index :client_feedbacks, :triggered_by_round
    add_index :client_feedbacks, :deleted_at
  end
end
