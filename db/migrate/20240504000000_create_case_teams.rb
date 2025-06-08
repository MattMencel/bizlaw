class CreateCaseTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :case_teams, id: :uuid do |t|
      t.references :case, null: false, foreign_key: true, type: :uuid
      t.references :team, null: false, foreign_key: true, type: :uuid
      t.string :role, null: false
      t.timestamps
    end
    add_index :case_teams, [:case_id, :role], unique: true
    add_index :case_teams, [:case_id, :team_id], unique: true
  end
end
