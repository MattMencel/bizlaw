# frozen_string_literal: true

# The Action Budget: the values a Case authors it from, the one knob a Section
# may turn, and the quota rows a Day's open writes for each Side.
#
# ADR 0002 names `day_budgets.spent` as the schema's single materialized
# exception. The halves are two ceilings rather than one, so the exception is
# two counter pairs in one row, each carrying its own CHECK. Nothing spends
# yet — both `spent` columns stay at zero until the Docket and its trigger
# arrive.
class CreateDayBudgets < ActiveRecord::Migration[8.0]
  def up
    # Authored per Version, because a published Version never changes again and
    # Par was measured against these numbers. The exchange half is an absolute
    # count of points, never a share of the Budget: held as a fraction the brake
    # couples silently to the Budget size, and a fifth of nine falls under two.
    change_table :case_versions, bulk: true do |t|
      t.integer :budget_per_day, null: false
      t.integer :exchange_pool, null: false
      t.decimal :closing_knee, precision: 3, scale: 2, null: false
      t.integer :closing_preparation, null: false
      t.integer :closing_exchange, null: false
    end
    add_check_constraint :case_versions, "exchange_pool >= 2",
      name: "case_versions_exchange_pool_plays_an_offer"
    add_check_constraint :case_versions, "closing_exchange >= 2",
      name: "case_versions_closing_exchange_plays_an_offer"

    # A Section may set the Budget size; everything else about the Budget is the
    # Case's. Null is the Case's reference value, so a Section that never turned
    # the knob has nothing recorded to disagree with it.
    add_column :sections, :budget_per_day, :integer

    # Written when the Day opens and never recomputed, so a Section edit
    # mid-Simulation reaches later Days only.
    create_table :day_budgets do |t|
      t.bigint :organization_id, null: false
      t.bigint :side_id, null: false
      t.bigint :day_id, null: false
      t.integer :preparation_budget, null: false
      t.integer :preparation_spent, null: false, default: 0
      t.integer :exchange_budget, null: false
      t.integer :exchange_spent, null: false, default: 0

      t.timestamps

      # The Budget is the one ceiling in the game whose behaviour at the
      # boundary is a refusal, and a constraint expresses refusal natively.
      t.check_constraint "preparation_spent <= preparation_budget",
        name: "day_budgets_preparation_within_budget"
      t.check_constraint "exchange_spent <= exchange_budget",
        name: "day_budgets_exchange_within_budget"
      # A Budget size set below the exchange pool would otherwise write a
      # negative preparation half rather than refusing.
      t.check_constraint "preparation_budget >= 0",
        name: "day_budgets_preparation_budget_non_negative"
      # Below two points nothing can be played at all — an Offer costs one and
      # the Exhibit riding it costs another. The Case's own halves are CHECKed
      # at two, but the taper narrows the exchange half to the Budget size, so
      # a Section shrinking the Budget under the pool would quietly take it out
      # of the brake. This is where that lands loudly instead.
      t.check_constraint "exchange_budget >= 2",
        name: "day_budgets_exchange_budget_plays_an_offer"
    end
    add_index :day_budgets, [:side_id, :day_id], unique: true
    add_index :day_budgets, :day_id
    add_foreign_key :day_budgets, :sides,
      column: [:side_id, :organization_id], primary_key: [:id, :organization_id]
    add_foreign_key :day_budgets, :days,
      column: [:day_id, :organization_id], primary_key: [:id, :organization_id]
  end

  # Written out rather than left to `change`, because Rails cannot auto-reverse
  # `add_foreign_key` on a composite key under SQLite: the key lives inside the
  # table definition, so `remove_foreign_key` finds nothing to remove and the
  # rollback raises. Dropping the table takes its keys with it.
  def down
    drop_table :day_budgets
    remove_column :sections, :budget_per_day
    remove_check_constraint :case_versions, "exchange_pool >= 2",
      name: "case_versions_exchange_pool_plays_an_offer"
    remove_check_constraint :case_versions, "closing_exchange >= 2",
      name: "case_versions_closing_exchange_plays_an_offer"
    change_table :case_versions, bulk: true do |t|
      t.remove :budget_per_day, :exchange_pool, :closing_knee,
        :closing_preparation, :closing_exchange
    end
  end
end
