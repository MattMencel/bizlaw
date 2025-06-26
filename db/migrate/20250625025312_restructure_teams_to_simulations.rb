# frozen_string_literal: true

class RestructureTeamsToSimulations < ActiveRecord::Migration[8.0]
  def up
    # Add new columns to teams table
    add_reference :teams, :simulation, null: true, foreign_key: true, type: :uuid
    add_column :teams, :role, :string
    add_index :teams, [:simulation_id, :role]

    # Create default simulations for existing case-team assignments
    migrate_existing_data

    # Remove old associations after data migration
    remove_foreign_key :teams, :courses if foreign_key_exists?(:teams, :courses)
    remove_reference :teams, :course, type: :uuid

    # Remove plaintiff_team_id and defendant_team_id from simulations
    # since we now use the teams.simulation_id relationship
    remove_reference :simulations, :plaintiff_team, type: :uuid if column_exists?(:simulations, :plaintiff_team_id)
    remove_reference :simulations, :defendant_team, type: :uuid if column_exists?(:simulations, :defendant_team_id)

    # Make simulation_id required after migration
    change_column_null :teams, :simulation_id, false

    # Drop the case_teams join table
    drop_table :case_teams if table_exists?(:case_teams)
  end

  def down
    # Recreate case_teams table
    create_table :case_teams, id: :uuid do |t|
      t.references :case, null: false, foreign_key: true, type: :uuid
      t.references :team, null: false, foreign_key: true, type: :uuid
      t.string :role, null: false
      t.timestamps
      t.datetime :deleted_at
    end

    add_index :case_teams, [:case_id, :role], unique: true
    add_index :case_teams, [:case_id, :team_id], unique: true

    # Add back course relationship to teams
    add_reference :teams, :course, null: true, foreign_key: true, type: :uuid

    # Add back plaintiff/defendant team references to simulations
    add_reference :simulations, :plaintiff_team, foreign_key: {to_table: :teams}, type: :uuid
    add_reference :simulations, :defendant_team, foreign_key: {to_table: :teams}, type: :uuid

    # Migrate data back to old structure
    reverse_migrate_data

    # Remove new columns
    remove_index :teams, [:simulation_id, :role] if index_exists?(:teams, [:simulation_id, :role])
    remove_column :teams, :role
    remove_reference :teams, :simulation, type: :uuid

    # Make course_id required again
    change_column_null :teams, :course_id, false
  end

  private

  def migrate_existing_data
    # For each case that has teams assigned via case_teams
    execute <<-SQL
      INSERT INTO simulations (id, case_id, status, total_rounds, current_round,
                              start_date, simulation_config, created_at, updated_at,
                              plaintiff_min_acceptable, plaintiff_ideal,
                              defendant_max_acceptable, defendant_ideal)
      SELECT
        gen_random_uuid(),
        c.id,
        'setup',
        5,
        1,
        CURRENT_DATE,
        '{}',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        100000,
        250000,
        150000,
        50000
      FROM cases c
      WHERE c.id IN (
        SELECT DISTINCT case_id FROM case_teams
      )
      AND c.id NOT IN (
        SELECT DISTINCT case_id FROM simulations WHERE case_id IS NOT NULL
      )
    SQL

    # Update teams to belong to simulations and set their roles
    execute <<-SQL
      UPDATE teams
      SET simulation_id = s.id,
          role = ct.role
      FROM case_teams ct
      JOIN simulations s ON s.case_id = ct.case_id
      WHERE teams.id = ct.team_id
      AND s.case_id = ct.case_id
    SQL
  end

  def reverse_migrate_data
    # Recreate case_teams from simulation teams
    execute <<-SQL
      INSERT INTO case_teams (id, case_id, team_id, role, created_at, updated_at)
      SELECT
        gen_random_uuid(),
        s.case_id,
        t.id,
        t.role,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      FROM teams t
      JOIN simulations s ON s.id = t.simulation_id
      WHERE t.simulation_id IS NOT NULL
    SQL

    # Update teams to belong back to courses
    execute <<-SQL
      UPDATE teams
      SET course_id = c.id
      FROM simulations s
      JOIN cases cas ON cas.id = s.case_id
      JOIN courses c ON c.id = cas.course_id
      WHERE teams.simulation_id = s.id
    SQL

    # Update simulations to reference teams directly
    execute <<-SQL
      UPDATE simulations
      SET plaintiff_team_id = (
        SELECT t.id FROM teams t
        WHERE t.simulation_id = simulations.id
        AND t.role = 'plaintiff'
        LIMIT 1
      ),
      defendant_team_id = (
        SELECT t.id FROM teams t
        WHERE t.simulation_id = simulations.id
        AND t.role = 'defendant'
        LIMIT 1
      )
    SQL
  end
end
