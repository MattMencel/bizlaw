class CreatePerformanceScores < ActiveRecord::Migration[8.0]
  def change
    create_table :performance_scores, id: :uuid do |t|
      t.references :simulation, null: false, foreign_key: true, type: :uuid
      t.references :team, null: false, foreign_key: true, type: :uuid
      t.references :user, null: true, foreign_key: true, type: :uuid # null for team scores
      t.decimal :settlement_quality_score, precision: 5, scale: 2
      t.decimal :legal_strategy_score, precision: 5, scale: 2
      t.decimal :collaboration_score, precision: 5, scale: 2
      t.decimal :efficiency_score, precision: 5, scale: 2
      t.decimal :speed_bonus, precision: 5, scale: 2
      t.decimal :creative_terms_score, precision: 5, scale: 2
      t.decimal :total_score, precision: 6, scale: 2, null: false
      t.jsonb :score_breakdown, default: {}, null: false
      t.datetime :scored_at, null: false
      t.string :score_type, null: false # 'individual' or 'team'
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :performance_scores, [:simulation_id, :team_id, :user_id], unique: true, where: "user_id IS NOT NULL"
    add_index :performance_scores, [:simulation_id, :team_id], unique: true, where: "user_id IS NULL"
    add_index :performance_scores, :total_score
    add_index :performance_scores, :score_type
    add_index :performance_scores, :deleted_at
  end
end
