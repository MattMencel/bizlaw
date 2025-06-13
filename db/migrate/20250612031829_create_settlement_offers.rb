class CreateSettlementOffers < ActiveRecord::Migration[8.0]
  def change
    create_enum :offer_type, ["initial_demand", "counteroffer", "final_offer"]

    create_table :settlement_offers, id: :uuid do |t|
      t.references :negotiation_round, null: false, foreign_key: true, type: :uuid
      t.references :team, null: false, foreign_key: true, type: :uuid
      t.enum :offer_type, enum_type: "offer_type", null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.text :justification, null: false
      t.text :non_monetary_terms
      t.references :submitted_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.datetime :submitted_at, null: false
      t.decimal :quality_score, precision: 5, scale: 2
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :settlement_offers, [:negotiation_round_id, :team_id], unique: true
    add_index :settlement_offers, :offer_type
    add_index :settlement_offers, :submitted_at
    add_index :settlement_offers, :deleted_at
  end
end
