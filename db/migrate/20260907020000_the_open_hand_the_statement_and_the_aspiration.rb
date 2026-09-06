# frozen_string_literal: true

# What a Team walks in with, what its Client says on the way in, and what that
# Client says it wants — the three authored objects the Morning Briefing and the
# Terms Board compose from and the Case could not yet express.
#
# All three are `:authored`. Per the repo's rule for that tier, each required
# column arrives `null: false` with **no default**: a Case Version that predates
# them is not silently given a plausible value, it fails this migration and is
# re-imported. A backfilled default would make the declaration decorative on
# exactly the rows a grading dispute might reach.
class TheOpenHandTheStatementAndTheAspiration < ActiveRecord::Migration[8.0]
  # Provenance's authored three. The one-Side hands are named by the role that
  # holds them, so the favorable-Exhibit CHECK below can compare a hand against
  # a target without a second column to say whose hand it is.
  PROVENANCES = %w[both_sides plaintiff defendant discoverable].freeze

  def up
    # A document in hand at the open waits behind no Action, so the column that
    # said every document does has to stop saying it. What keeps *doors visible,
    # contents hidden* checkable is now the xor below rather than the NOT NULL.
    change_column_null :case_documents, :case_action_id, true

    add_column :case_documents, :provenance, :string, null: false

    add_check_constraint :case_documents,
      "provenance IN (#{PROVENANCES.map { |p| "'#{p}'" }.join(", ")})",
      name: "case_documents_provenance_known"

    # The xor. A discoverable document sits behind exactly one Action; one in
    # hand at the open sits behind none. Neither half is sayable without the
    # other, so a document cannot be both something a Team starts with and
    # something it finds.
    add_check_constraint :case_documents,
      "(provenance = 'discoverable') = (case_action_id IS NOT NULL)",
      name: "case_documents_door_or_hand"

    # Ammunition a Team walks in with is a position the Case authored and Par is
    # authored against it. An *unfavorable* Exhibit at the open is refused: its
    # shift would land before the first Day is played, spending the Client's
    # bound with no Docket line behind it and no beat to read it in.
    #
    # A `both_sides` document is in the hand of the Side it would target
    # whichever Side that is, so it may carry no Exhibit at all. That falls out
    # of the same constraint rather than needing its own.
    add_check_constraint :case_documents, <<~SQL.squish,
      provenance = 'discoverable'
        OR exhibit_target_role IS NULL
        OR (provenance IN ('plaintiff', 'defendant') AND exhibit_target_role != provenance)
    SQL
      name: "case_documents_open_hand_exhibit_is_favorable"

    # What the Client says they want, in their own words, on the Day the Team
    # first sits down. Authored prose that never reaches the model — it is an
    # object in the dispute, not a line about something the engine computed.
    add_column :case_clients, :opening_statement, :text, null: false

    # The target of the composite key from the aspirations below.
    add_index :case_clients, [:id, :case_version_id], unique: true

    # What a Client says out loud about one Term, and the Terms Board's third
    # track. Distinct from the private valuation the same Client puts on the
    # same Term: that is what an Offer is scored by and no student ever sees it.
    #
    # The set is **sparse**. A Term with no row here is one this Client is
    # indifferent about, and its track carries the two live positions and no
    # marker — which is why nothing demands one row per Client per Term.
    #
    # `amount_cents` is nullable for the same reason `staged_offer_terms`' is: a
    # Client wanting an apology wants an apology, and there is no figure to put
    # on it. An aspiration does not move, so there is no ledger here — it is
    # authored and read.
    create_table :case_client_aspirations do |t|
      t.bigint :case_version_id, null: false
      t.bigint :case_client_id, null: false
      t.bigint :case_term_id, null: false
      t.integer :amount_cents

      t.timestamps

      t.check_constraint "amount_cents IS NULL OR amount_cents > 0",
        name: "case_client_aspirations_amount_is_money"
    end
    add_index :case_client_aspirations, [:case_client_id, :case_term_id], unique: true
    add_index :case_client_aspirations, :case_term_id
    add_foreign_key :case_client_aspirations, :case_clients,
      column: [:case_client_id, :case_version_id], primary_key: [:id, :case_version_id]
    add_foreign_key :case_client_aspirations, :case_terms,
      column: [:case_term_id, :case_version_id], primary_key: [:id, :case_version_id]
  end

  def down
    drop_table :case_client_aspirations
    remove_index :case_clients, [:id, :case_version_id]
    remove_column :case_clients, :opening_statement
    remove_check_constraint :case_documents, name: "case_documents_open_hand_exhibit_is_favorable"
    remove_check_constraint :case_documents, name: "case_documents_door_or_hand"
    remove_check_constraint :case_documents, name: "case_documents_provenance_known"
    remove_column :case_documents, :provenance
    change_column_null :case_documents, :case_action_id, false
  end
end
