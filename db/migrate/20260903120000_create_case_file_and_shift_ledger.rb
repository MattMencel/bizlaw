# frozen_string_literal: true

# What preparation yields, and what a discovery that hurts costs.
#
# The authored half: the Client an Exhibit targets, the Terms vocabulary an
# Exhibit bears on, and the documents waiting behind an Action. An Exhibit is an
# authored **property** some documents carry and most do not, so it is nullable
# columns on `case_documents` rather than a table of its own — preparation
# yields one thing rather than two.
#
# The run's half: the Case File a landing fills, and the shift ledger a Client's
# bound is folded from. The bound is ADR 0002's deliberate contrast with the
# Budget — its ceiling saturates rather than refusing, so there is no CHECK on
# it and `applied_fraction` is computed by the model instead.
class CreateCaseFileAndShiftLedger < ActiveRecord::Migration[8.0]
  def up
    # The Client is the only Party the engine holds a record for: an Exhibit
    # targets one, and only a Client carries a bound. Two per Version, one for
    # each Side's role, capped by unique index.
    #
    # The bound is the total inward travel a Client may make across one
    # Simulation, and it is the one thing about a Client authored as money.
    # Every shift against it is a fraction of it, so an Exhibit is worth the
    # same share of a Client's travel whether the Section made that Client easy
    # or hard.
    create_table :case_clients do |t|
      t.references :case_version, null: false, foreign_key: true
      t.string :role, null: false
      t.integer :bound_cents, null: false

      t.timestamps

      t.check_constraint "role IN ('plaintiff', 'defendant')", name: "case_clients_role_known"
      t.check_constraint "bound_cents > 0", name: "case_clients_bound_is_travel"
    end
    add_index :case_clients, [:case_version_id, :role], unique: true

    # The vocabulary an Offer is built from and an Exhibit bears on: money plus
    # the non-monetary terms this Case authors. Terms are atomic — a public
    # apology and a private one are two Terms, never one Term with a setting.
    create_table :case_terms do |t|
      t.references :case_version, null: false, foreign_key: true
      t.string :key, null: false

      t.timestamps
    end
    add_index :case_terms, [:case_version_id, :key], unique: true
    # The target of the composite key from the join below.
    add_index :case_terms, [:id, :case_version_id], unique: true

    # The target of the composite key from `case_documents`: a document cannot
    # wait behind an Action of another Version.
    add_index :case_actions, [:id, :case_version_id], unique: true

    # Everything in the Case File is a document. This is the authored one,
    # waiting behind the Action that discovers it — Provenance's third kind, and
    # the only one this ticket needs. `exhibit_target_role` and
    # `exhibit_shift_fraction` are the Exhibit property: both null on a document
    # that carries none, both present on one that does.
    #
    # The shift is authored positive because player-caused movement is a
    # ratchet: an Exhibit only ever moves a reservation point toward
    # settleability. That is the sign. Only an Event moves one back outward, and
    # it writes its negative straight into the shift ledger, which is why the
    # ledger's own CHECK is written over `abs`.
    create_table :case_documents do |t|
      t.bigint :case_version_id, null: false
      t.bigint :case_action_id, null: false
      t.string :identifier, null: false
      t.string :title, null: false
      t.text :body, null: false
      t.string :exhibit_target_role
      t.decimal :exhibit_shift_fraction, precision: 5, scale: 4

      t.timestamps

      t.check_constraint <<~SQL.squish, name: "case_documents_exhibit_is_whole_or_absent"
        (exhibit_target_role IS NULL) = (exhibit_shift_fraction IS NULL)
      SQL
      t.check_constraint <<~SQL.squish, name: "case_documents_exhibit_target_known"
        exhibit_target_role IS NULL OR exhibit_target_role IN ('plaintiff', 'defendant')
      SQL
      # A fraction of the target's bound, and the ratchet's direction.
      t.check_constraint <<~SQL.squish, name: "case_documents_exhibit_shift_is_inward"
        exhibit_shift_fraction IS NULL
          OR (exhibit_shift_fraction > 0 AND exhibit_shift_fraction <= 1)
      SQL
    end
    add_index :case_documents, [:case_version_id, :identifier], unique: true
    add_index :case_documents, :case_action_id
    add_index :case_documents, [:id, :case_version_id], unique: true
    add_foreign_key :case_documents, :case_versions
    add_foreign_key :case_documents, :case_actions,
      column: [:case_action_id, :case_version_id], primary_key: [:id, :case_version_id]

    # The Terms an Exhibit bears on. It moves a Client only where the Offer it
    # rides touches one of them, so a reinstatement argument is worth nothing
    # attached to a cash-only Offer. Nothing reads the intersection yet.
    create_table :case_document_terms do |t|
      t.bigint :case_version_id, null: false
      t.bigint :case_document_id, null: false
      t.bigint :case_term_id, null: false

      t.timestamps
    end
    add_index :case_document_terms, [:case_document_id, :case_term_id], unique: true
    add_index :case_document_terms, :case_term_id
    add_foreign_key :case_document_terms, :case_documents,
      column: [:case_document_id, :case_version_id], primary_key: [:id, :case_version_id]
    add_foreign_key :case_document_terms, :case_terms,
      column: [:case_term_id, :case_version_id], primary_key: [:id, :case_version_id]

    # The target of the composite key from `case_file_documents`, which is what
    # pins a filed document to the Version its Simulation actually pinned.
    add_index :simulations, [:id, :case_version_id], unique: true

    # The Case File: what this Team knows. One row per Side per authored
    # document, written when the Action that discovered it lands. The unique
    # index is what makes a second landing — a double Day-open, or a Team that
    # bought the same Action twice — harmless rather than merely improbable.
    #
    # `case_version_id` is carried rather than joined for, and the two keys over
    # it meet in the middle: it must be the Version the document belongs to and
    # the Version the Simulation pinned, so a Case File cannot come to hold a
    # document from a Case nobody in this run is playing.
    create_table :case_file_documents do |t|
      t.bigint :organization_id, null: false
      t.bigint :simulation_id, null: false
      t.bigint :case_version_id, null: false
      t.bigint :side_id, null: false
      t.bigint :day_id, null: false
      t.bigint :case_document_id, null: false

      t.timestamps
    end
    add_index :case_file_documents, [:side_id, :case_document_id], unique: true
    add_index :case_file_documents, :day_id
    add_index :case_file_documents, :case_document_id
    add_foreign_key :case_file_documents, :sides,
      column: [:side_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :case_file_documents, :days,
      column: [:day_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :case_file_documents, :case_documents,
      column: [:case_document_id, :case_version_id], primary_key: [:id, :case_version_id]
    add_foreign_key :case_file_documents, :simulations,
      column: [:simulation_id, :case_version_id], primary_key: [:id, :case_version_id]

    # The shift ledger. `side_id` is the Side whose *own* Client moves: an
    # unfavorable discovery moves the finder's, and a played Exhibit will move
    # the opposing one. Bound consumed is a fold over these rows and never a
    # column, because the bound saturates rather than refusing and a counter
    # with a CHECK on it would crash on a legal play.
    #
    # `applied_fraction` is computed by the model and never supplied by the
    # caller. The CHECK is what makes a forgotten clip loud; it is written over
    # `abs` so that an Event's outward shift — the ratchet's sole exemption —
    # lands under the same rule.
    create_table :client_shifts do |t|
      t.bigint :organization_id, null: false
      t.bigint :simulation_id, null: false
      t.bigint :side_id, null: false
      t.bigint :day_id, null: false
      t.string :source_kind, null: false
      t.bigint :source_ref, null: false
      t.decimal :requested_fraction, precision: 5, scale: 4, null: false
      t.decimal :applied_fraction, precision: 5, scale: 4, null: false

      t.timestamps

      t.check_constraint "abs(applied_fraction) <= abs(requested_fraction)",
        name: "client_shifts_applied_within_requested"
      # A shift is a fraction of the bound and no larger than the whole of it.
      # Its *direction* is not constrained here: player-caused movement is a
      # ratchet and says so in Ruby, but an Event's outward shift shares this
      # table and would trip a CHECK on the sign.
      t.check_constraint "requested_fraction != 0 AND abs(requested_fraction) <= 1",
        name: "client_shifts_requested_is_a_fraction_of_the_bound"
      t.check_constraint "source_kind IN ('unfavorable_discovery')",
        name: "client_shifts_source_kind_known"
    end
    # A shift lands exactly once.
    add_index :client_shifts, [:side_id, :source_kind, :source_ref], unique: true
    add_index :client_shifts, :day_id
    add_foreign_key :client_shifts, :sides,
      column: [:side_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :client_shifts, :days,
      column: [:day_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
  end

  # Written out rather than left to `change`, because Rails cannot auto-reverse
  # `add_foreign_key` on a composite key under SQLite: the key lives inside the
  # table definition, so `remove_foreign_key` finds nothing to remove and the
  # rollback raises. Dropping each table takes its keys with it; children first.
  def down
    drop_table :client_shifts
    drop_table :case_file_documents
    drop_table :case_document_terms
    drop_table :case_documents
    remove_index :simulations, [:id, :case_version_id]
    remove_index :case_actions, [:id, :case_version_id]
    drop_table :case_terms
    drop_table :case_clients
  end
end
