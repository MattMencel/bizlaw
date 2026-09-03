# frozen_string_literal: true

# The command seam's ledger: the Action menu a Case authors, the people a spend
# is attributed to, and the Docket rows every spend appends.
#
# The `AFTER INSERT` trigger at the bottom is ADR 0002's materialized exception
# doing its job. It **re-folds** both of `day_budgets`'s spent counters from the
# Docket rather than incrementing them: a fold cannot drift the way a lost or
# doubled delta can, and a trigger cannot be bypassed by an insert path added
# later that forgot to check.
class CreateDocketAndActionMenu < ActiveRecord::Migration[8.0]
  def up
    # Attribution is what lets a Team be a single party without the game losing
    # track of the people in it, so a spend names a person. Authentication is
    # not this ticket's; what is needed here is somebody for a Docket row to
    # point at, inside the Organization boundary.
    create_table :users do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email, null: false

      t.timestamps
    end
    add_index :users, [:organization_id, :email], unique: true
    # The target of the composite foreign key from `docket_entries`.
    add_index :users, [:id, :organization_id], unique: true

    # An Action kind is engine; its instances and prices are authored per Case,
    # because the economy is teaching material rather than engine constants. A
    # Case authors at most one instance of each kind, capped by unique index.
    create_table :case_actions do |t|
      t.references :case_version, null: false, foreign_key: true
      t.string :kind, null: false
      t.integer :cost, null: false
      t.integer :lead_time_days, null: false
      t.string :half, null: false

      t.timestamps

      t.check_constraint "cost >= 1", name: "case_actions_cost_is_a_spend"
      t.check_constraint "lead_time_days >= 0", name: "case_actions_lead_time_not_negative"
      t.check_constraint "half IN ('preparation', 'exchange')", name: "case_actions_half_known"
    end
    add_index :case_actions, [:case_version_id, :kind], unique: true

    # The Team's chronological record of Actions taken: what was spent, which
    # member spent it, and the Day its result lands. It carries the cost and the
    # half it drew on rather than joining for them, because the row is the
    # ledger's own record of what was charged — and because the trigger folds
    # them without a join.
    create_table :docket_entries do |t|
      t.bigint :organization_id, null: false
      # Tenancy is the Simulation as well as the Organization, so a row cannot
      # pair a Side from one run with a Day from another inside one institution.
      t.bigint :simulation_id, null: false
      t.bigint :side_id, null: false
      t.bigint :day_id, null: false
      t.bigint :lands_on_day_id, null: false
      t.bigint :spent_by_user_id, null: false
      t.references :case_action, null: false, foreign_key: true
      t.integer :cost, null: false
      t.string :half, null: false

      t.timestamps

      t.check_constraint "cost >= 1", name: "docket_entries_cost_is_a_spend"
      t.check_constraint "half IN ('preparation', 'exchange')", name: "docket_entries_half_known"
    end
    add_index :docket_entries, [:side_id, :day_id]
    add_index :docket_entries, :lands_on_day_id
    add_foreign_key :docket_entries, :sides,
      column: [:side_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :docket_entries, :days,
      column: [:day_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    # A result cannot land on a Day of another run either.
    add_foreign_key :docket_entries, :days,
      column: [:lands_on_day_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :docket_entries, :users,
      column: [:spent_by_user_id, :organization_id], primary_key: [:id, :organization_id]

    # A Docket row for a Day that has not opened has no quota to fold into, and
    # the fold below would silently no-op on it — leaving `Days::Open` to write
    # that Day's quota at nothing spent and hand the points back. Refusing it
    # here is what keeps the fold's guarantee true for an insert path added
    # later that forgot to ask the seam.
    execute(<<~SQL)
      CREATE TRIGGER docket_entries_need_an_opened_day
      BEFORE INSERT ON docket_entries
      WHEN NOT EXISTS (
        SELECT 1 FROM day_budgets
        WHERE side_id = NEW.side_id AND day_id = NEW.day_id
      )
      BEGIN
        SELECT RAISE(ABORT, 'docket_entries_need_an_opened_day');
      END;
    SQL

    # Both halves are re-folded, not incremented. The exchange half stays at
    # zero until an Offer can commit, but a trigger that maintained one counter
    # and not the other would be a second insert path to remember.
    #
    # A fold that pushes either half past its budget trips that half's CHECK and
    # takes the insert down with it, which is what keeps the Budget off negative
    # for an insert path that never asked the seam.
    execute(<<~SQL)
      CREATE TRIGGER docket_entries_refold_day_budget_spent
      AFTER INSERT ON docket_entries
      BEGIN
        UPDATE day_budgets
        SET preparation_spent = (
              SELECT COALESCE(SUM(cost), 0) FROM docket_entries
              WHERE side_id = NEW.side_id AND day_id = NEW.day_id
                AND half = 'preparation'),
            exchange_spent = (
              SELECT COALESCE(SUM(cost), 0) FROM docket_entries
              WHERE side_id = NEW.side_id AND day_id = NEW.day_id
                AND half = 'exchange')
        WHERE side_id = NEW.side_id AND day_id = NEW.day_id;
      END;
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS docket_entries_refold_day_budget_spent;"
    execute "DROP TRIGGER IF EXISTS docket_entries_need_an_opened_day;"
    drop_table :docket_entries
    drop_table :case_actions
    drop_table :users
  end
end
