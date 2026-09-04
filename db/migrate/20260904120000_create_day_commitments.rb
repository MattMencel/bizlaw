# frozen_string_literal: true

# A Side declaring itself finished with a Day, and the clock the Instructor may
# move.
#
# A Day closes when both Sides have committed it, when the Instructor's deadline
# fires, or when the Instructor force-closes it. ADR 0002 makes that one write —
# `UPDATE days SET closed_at = ? WHERE id = ? AND closed_at IS NULL` — so the
# only thing the schema owes it is a ledger to count commitments from and a
# column to hold the deadline.
class CreateDayCommitments < ActiveRecord::Migration[8.0]
  def up
    # Null is a Day with no clock on it, which is every Day until an Instructor
    # sets one. The Section's deadline *schedule* is a Section knob nobody has
    # built; this is the per-Day time the sweep reads and the extension moves,
    # because two concurrent Simulations of one Section run at different paces.
    add_column :days, :deadline_at, :datetime

    # Append-only, one row per Side per Day, and the second one written is what
    # closes the Day. It carries Attribution for the same reason the Docket
    # does: a Team acts as a single party without the game losing track of the
    # people in it, and an Instructor reading back a stalled Simulation wants to
    # know which student ended the Day.
    #
    # The unique index is what makes a second commit from the same Side
    # harmless rather than merely improbable — three students looking at the
    # same button is the ordinary case, not an error.
    create_table :day_commitments do |t|
      t.bigint :organization_id, null: false
      t.bigint :simulation_id, null: false
      t.bigint :side_id, null: false
      t.bigint :day_id, null: false
      t.bigint :committed_by_user_id, null: false

      t.timestamps
    end
    add_index :day_commitments, [:side_id, :day_id], unique: true
    add_index :day_commitments, :day_id
    add_foreign_key :day_commitments, :sides,
      column: [:side_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :day_commitments, :days,
      column: [:day_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :day_commitments, :users,
      column: [:committed_by_user_id, :organization_id],
      primary_key: [:id, :organization_id]

    # A commitment written after the close would be a record saying both Sides
    # finished a Day that was taken from them. The service refuses it too, but
    # against a Day it holds in memory; this is the rule where a stale object
    # cannot get past it.
    execute <<~SQL
      CREATE TRIGGER day_commitments_need_an_unclosed_day
      BEFORE INSERT ON day_commitments
      WHEN EXISTS (
        SELECT 1 FROM days WHERE id = NEW.day_id AND closed_at IS NOT NULL
      )
      BEGIN
        SELECT RAISE(ABORT, 'day_commitments_need_an_unclosed_day');
      END;
    SQL

    # Remaining Budget expires at close, and this is what makes that structural
    # rather than a rule the command seam has to remember. It is the mirror of
    # `docket_entries_need_an_opened_day`, which refuses a spend on a Day whose
    # quota has not been written; between them a Docket row can only be
    # appended to a Day that is open now.
    execute <<~SQL
      CREATE TRIGGER docket_entries_need_an_unclosed_day
      BEFORE INSERT ON docket_entries
      WHEN EXISTS (
        SELECT 1 FROM days WHERE id = NEW.day_id AND closed_at IS NOT NULL
      )
      BEGIN
        SELECT RAISE(ABORT, 'docket_entries_need_an_unclosed_day');
      END;
    SQL
  end

  # Written out rather than left to `change`, because Rails cannot auto-reverse
  # `add_foreign_key` on a composite key under SQLite: the key lives inside the
  # table definition, so `remove_foreign_key` finds nothing to remove and the
  # rollback raises. Dropping the table takes its keys with it.
  def down
    execute "DROP TRIGGER IF EXISTS docket_entries_need_an_unclosed_day"
    execute "DROP TRIGGER IF EXISTS day_commitments_need_an_unclosed_day"
    drop_table :day_commitments
    remove_column :days, :deadline_at
  end
end
