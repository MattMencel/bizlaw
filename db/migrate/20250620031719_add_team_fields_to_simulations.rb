class AddTeamFieldsToSimulations < ActiveRecord::Migration[8.0]
  def change
    # Add team reference fields (nullable for setup phase)
    add_reference :simulations, :plaintiff_team, null: true, foreign_key: { to_table: :teams }, type: :uuid
    add_reference :simulations, :defendant_team, null: true, foreign_key: { to_table: :teams }, type: :uuid

    # Make start_date nullable (only required when simulation is active)
    change_column_null :simulations, :start_date, true

    # Make financial fields nullable (only required when simulation is active)
    change_column_null :simulations, :plaintiff_min_acceptable, true
    change_column_null :simulations, :plaintiff_ideal, true
    change_column_null :simulations, :defendant_max_acceptable, true
    change_column_null :simulations, :defendant_ideal, true

    # Indexes are automatically created by add_reference
  end
end
