# frozen_string_literal: true

# The Offer before it is committed, the gate inside a Team, and the Instructor's
# release of that gate.
#
# Per ADR 0002, **staged and committed Offers are separate tables**, so that
# every cross-Side read targets one that structurally contains no live
# positions. The alternative was one table where safety depended on remembering
# a predicate, and the leak it guards is the opponent's current negotiating
# position — the worst one available. `committed_offers` is created here and
# stays empty until the commit path is built; its Terms arrive with it.
#
# Staging writes no Docket row, because nothing has been spent. `docket_entries`
# carries `CHECK (cost >= 1)` and points at an authored Action, so a staging
# could not be one of its rows even if the design wanted it to be. The Docket a
# teammate reads is therefore a fold over three ledgers — see `Docket`.
class CreateOffersAndTheSecond < ActiveRecord::Migration[8.0]
  def up
    # One live draft per Side per Day. It is keyed `(side_id, day_id)` like
    # every other run table rather than to the Side alone: the exchange half an
    # Offer commits out of is per-Day and expires at close, so a draft that
    # outlived the Day would be a position with no Budget behind it, and the
    # Docket entry it is read back as would silently change Days when revised.
    #
    # `case_version_id` is carried so the Terms below can key to the Version the
    # Simulation pinned; the two keys over it meet in the middle exactly as they
    # do on `case_file_documents`.
    #
    # `note` is free text the Instructor reads and is not part of the
    # vocabulary. It is the row's `:prose` while the Offer's shape is
    # `:skeleton`.
    create_table :staged_offers do |t|
      t.bigint :organization_id, null: false
      t.bigint :simulation_id, null: false
      t.bigint :case_version_id, null: false
      t.bigint :side_id, null: false
      t.bigint :day_id, null: false
      # Who put the position now on the table there — the stager, or whoever
      # last revised it. It is what the Second is measured against, so a
      # revision moves it: the member who wrote these terms is never the member
      # who confirms them.
      t.bigint :staged_by_user_id, null: false
      t.text :note

      t.timestamps
    end
    add_index :staged_offers, [:side_id, :day_id], unique: true
    add_index :staged_offers, :day_id
    # The target of the composite key from `staged_offer_terms`.
    add_index :staged_offers, [:id, :case_version_id], unique: true
    add_foreign_key :staged_offers, :sides,
      column: [:side_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :staged_offers, :days,
      column: [:day_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :staged_offers, :users,
      column: [:staged_by_user_id, :organization_id], primary_key: [:id, :organization_id]
    add_foreign_key :staged_offers, :simulations,
      column: [:simulation_id, :case_version_id], primary_key: [:id, :case_version_id]

    # The shape of the deal, over the Case's authored Terms vocabulary. Terms
    # are atomic — a public apology and a private one are two Terms, never one
    # Term with a setting — so a Term appears on an Offer at most once and the
    # unique index says so.
    #
    # `amount_cents` is money's, and money's alone. That rule spans two tables —
    # it needs the Term's key — so per ADR 0002 it stays in Ruby; what the
    # database holds is that an amount is never negative.
    create_table :staged_offer_terms do |t|
      t.bigint :case_version_id, null: false
      t.bigint :staged_offer_id, null: false
      t.bigint :case_term_id, null: false
      t.integer :amount_cents

      t.timestamps

      t.check_constraint "amount_cents IS NULL OR amount_cents >= 0",
        name: "staged_offer_terms_amount_is_money"
    end
    add_index :staged_offer_terms, [:staged_offer_id, :case_term_id], unique: true
    add_index :staged_offer_terms, :case_term_id
    add_foreign_key :staged_offer_terms, :staged_offers,
      column: [:staged_offer_id, :case_version_id], primary_key: [:id, :case_version_id]
    add_foreign_key :staged_offer_terms, :case_terms,
      column: [:case_term_id, :case_version_id], primary_key: [:id, :case_version_id]

    # An Instructor's waiver of the Second, granted to one Team for one Day. It
    # is not a mechanic — it is what a Team whose other members are absent is
    # given — so it is scoped by the `(side_id, day_id)` key and there is no
    # query that could find it from tomorrow.
    #
    # The Instructor never Seconds on a Team's behalf, because Attribution would
    # then name someone who did not take the position. So this row names who
    # *granted* the waiver and nothing on it can be read as a Second.
    create_table :second_waivers do |t|
      t.bigint :organization_id, null: false
      t.bigint :simulation_id, null: false
      t.bigint :side_id, null: false
      t.bigint :day_id, null: false
      t.bigint :granted_by_user_id, null: false

      t.timestamps
    end
    add_index :second_waivers, [:side_id, :day_id], unique: true
    add_index :second_waivers, :day_id
    add_foreign_key :second_waivers, :sides,
      column: [:side_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :second_waivers, :days,
      column: [:day_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :second_waivers, :users,
      column: [:granted_by_user_id, :organization_id], primary_key: [:id, :organization_id]

    # The table every cross-Side read targets, created empty. Committing an
    # Offer is a Boardroom act, at most one per Side per Day, so the key says
    # so.
    #
    # `seconded_by_user_id` is null on an Offer that landed under a waiver, and
    # that is the only way it is ever null. The CHECK is ADR 0002's Second: it
    # is written plainly rather than guarded for null because in SQL a CHECK
    # fails only on false, and `NULL != x` is neither.
    create_table :committed_offers do |t|
      t.bigint :organization_id, null: false
      t.bigint :simulation_id, null: false
      t.bigint :case_version_id, null: false
      t.bigint :side_id, null: false
      t.bigint :day_id, null: false
      t.bigint :staged_by_user_id, null: false
      t.bigint :seconded_by_user_id
      t.text :note

      t.timestamps

      t.check_constraint "seconded_by_user_id != staged_by_user_id",
        name: "committed_offers_second_is_another_member"
    end
    add_index :committed_offers, [:side_id, :day_id], unique: true
    add_index :committed_offers, :day_id
    add_index :committed_offers, [:id, :case_version_id], unique: true
    add_foreign_key :committed_offers, :sides,
      column: [:side_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :committed_offers, :days,
      column: [:day_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :committed_offers, :users,
      column: [:staged_by_user_id, :organization_id], primary_key: [:id, :organization_id]
    add_foreign_key :committed_offers, :users,
      column: [:seconded_by_user_id, :organization_id], primary_key: [:id, :organization_id]
    add_foreign_key :committed_offers, :simulations,
      column: [:simulation_id, :case_version_id], primary_key: [:id, :case_version_id]

    # A position staged onto a Day that has already ended is a draft nobody can
    # commit, against a Budget that has already expired. The services refuse it
    # against a Day they hold in memory; this is the rule where a stale object
    # cannot get past it, and it is the mirror of the two triggers the Docket
    # and the commitment ledger already carry.
    execute <<~SQL
      CREATE TRIGGER staged_offers_need_an_unclosed_day
      BEFORE INSERT ON staged_offers
      WHEN EXISTS (
        SELECT 1 FROM days WHERE id = NEW.day_id AND closed_at IS NOT NULL
      )
      BEGIN
        SELECT RAISE(ABORT, 'staged_offers_need_an_unclosed_day');
      END;
    SQL

    # A waiver of a gate on a Day nobody can still commit into is the same
    # nothing, and an Instructor granting one has misread the board rather than
    # helped a Team.
    execute <<~SQL
      CREATE TRIGGER second_waivers_need_an_unclosed_day
      BEFORE INSERT ON second_waivers
      WHEN EXISTS (
        SELECT 1 FROM days WHERE id = NEW.day_id AND closed_at IS NOT NULL
      )
      BEGIN
        SELECT RAISE(ABORT, 'second_waivers_need_an_unclosed_day');
      END;
    SQL
  end

  # Written out rather than left to `change`, because Rails cannot auto-reverse
  # `add_foreign_key` on a composite key under SQLite: the key lives inside the
  # table definition, so `remove_foreign_key` finds nothing to remove and the
  # rollback raises. Dropping each table takes its keys with it; children first.
  def down
    execute "DROP TRIGGER IF EXISTS second_waivers_need_an_unclosed_day"
    execute "DROP TRIGGER IF EXISTS staged_offers_need_an_unclosed_day"
    drop_table :committed_offers
    drop_table :second_waivers
    drop_table :staged_offer_terms
    drop_table :staged_offers
  end
end
