class CreateEvidenceReleases < ActiveRecord::Migration[8.0]
  def change
    create_table :evidence_releases, id: :uuid do |t|
      t.references :simulation, null: false, foreign_key: true, type: :uuid
      t.references :document, null: false, foreign_key: true, type: :uuid
      t.integer :release_round
      t.datetime :scheduled_release_at
      t.datetime :released_at
      t.jsonb :release_conditions, default: {}
      t.boolean :team_requested, default: false
      t.references :requesting_team, null: true, foreign_key: { to_table: :teams }, type: :uuid
      t.boolean :auto_release, default: true
      t.string :evidence_type
      t.text :impact_description
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :evidence_releases, :release_round
    add_index :evidence_releases, :scheduled_release_at
    add_index :evidence_releases, :released_at
    add_index :evidence_releases, :evidence_type
    add_index :evidence_releases, :deleted_at
    add_index :evidence_releases, [:simulation_id, :release_round]
    add_index :evidence_releases, [:simulation_id, :team_requested]
  end
end
