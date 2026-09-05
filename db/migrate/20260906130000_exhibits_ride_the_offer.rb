# frozen_string_literal: true

# Exhibits ride a committing Offer, and the document reaches the other Side at
# the same instant.
#
# Three tables' worth of change, and each one is a rule the design already
# states. An Exhibit is **attached to the staged Offer** rather than named at
# the commit, because the Second is the teammate confirming the whole play: a
# set of Exhibits chosen at the commit control would let the seconder play cards
# the member who took the position never proposed. So it hangs off
# `staged_offers` exactly as the Terms do, revisable and costing nothing until
# it lands.
#
# `played_exhibits` is what an Exhibit is spent by, and its unique index on the
# Case File row is what makes an Exhibit play exactly once — a Team that names a
# spent one on a later Day is refused rather than charged twice. It carries no
# relevance flag: whether the play moved the Client is a shift row's existence,
# derived on read like everything else that moves.
#
# The shift ledger grows a second player-caused kind and, with it, ADR 0003's
# partial unique index: both kinds key to the **receiving** Side's own Case File
# row, so one document moves one Client once however it reached them.
#
# `case_file_documents.served_at` is the service. A served document is knowledge
# and never ammunition, so the row reads back carrying no Exhibit property at
# all — see `CaseFileDocument`. It is a timestamp rather than a status column
# for the reason `days.closed_at` and `case_versions.published_at` are.
class ExhibitsRideTheOffer < ActiveRecord::Migration[8.0]
  # Named rather than left to Rails, which hashes names this long into something
  # a later migration cannot recognise.
  CASE_FILE_DOCUMENT_TENANCY_INDEX =
    "index_case_file_documents_on_id_simulation_and_organization"
  RIDING_EXHIBIT_INDEX = "index_staged_offer_exhibits_on_offer_and_document"
  ONE_MOVEMENT_PER_DOCUMENT_INDEX = "index_client_shifts_on_one_movement_per_document"

  def up
    # A served document is one this Team was shown rather than one it found. It
    # is the same row in the same Case File — service fills the folder the
    # ordinary way — and the flag is what strips the Exhibit property off it on
    # the way back out.
    add_column :case_file_documents, :served_at, :datetime

    # The targets of the composite keys below. `played_exhibits` keys the Case
    # File by tenancy, and the riding Exhibit keys both its parents by the Side
    # itself — a narrower key than the tenancy pair, because a Side belongs to
    # exactly one Simulation in exactly one Organization.
    add_index :case_file_documents, [:id, :simulation_id, :organization_id],
      unique: true, name: CASE_FILE_DOCUMENT_TENANCY_INDEX
    add_index :staged_offers, [:id, :side_id], unique: true
    add_index :case_file_documents, [:id, :side_id], unique: true

    riding_exhibits
    played_exhibits
    let_the_shift_ledger_take_a_played_exhibit
  end

  def down
    execute "DROP TRIGGER IF EXISTS played_exhibits_need_an_unclosed_day"
    execute "DROP TRIGGER IF EXISTS staged_offer_exhibits_need_an_unclosed_day"
    drop_table :played_exhibits
    drop_table :staged_offer_exhibits
    restore_the_shift_ledger_source_kinds
    remove_index :case_file_documents, [:id, :side_id]
    remove_index :staged_offers, [:id, :side_id]
    remove_index :case_file_documents, name: CASE_FILE_DOCUMENT_TENANCY_INDEX
    remove_column :case_file_documents, :served_at
  end

  private

  # The Exhibits riding the Team's live draft. Any number may ride one Offer;
  # what stops a Team dumping its hoard is the exchange half, which does not
  # carry to the next Day.
  #
  # Both parents are the run's own, so unlike `staged_offer_terms` this row
  # carries a key — and it is the **Side**, not the tenancy pair. The rule worth
  # holding is that a Team plays out of its own Case File, and tenancy alone
  # does not say so: two Sides share a Simulation and an Organization, so a
  # `(parent_id, simulation_id, organization_id)` key on both parents would
  # cheerfully take the opponent's document. `side_id` is the narrower key and
  # gives tenancy for nothing, because a Side belongs to exactly one Simulation
  # in exactly one Organization — the tenancy triple below is what pins it
  # there, and the two keys over `side_id` then meet in the middle.
  def riding_exhibits
    create_table :staged_offer_exhibits do |t|
      t.bigint :organization_id, null: false
      t.bigint :simulation_id, null: false
      t.bigint :side_id, null: false
      t.bigint :staged_offer_id, null: false
      t.bigint :case_file_document_id, null: false

      t.timestamps
    end
    # A document rides an Offer once. Naming it twice is a doubled control
    # press, not a Team playing one Exhibit for two points.
    add_index :staged_offer_exhibits, [:staged_offer_id, :case_file_document_id],
      unique: true, name: RIDING_EXHIBIT_INDEX
    add_index :staged_offer_exhibits, :case_file_document_id
    add_index :staged_offer_exhibits, :side_id
    add_foreign_key :staged_offer_exhibits, :sides,
      column: [:side_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :staged_offer_exhibits, :staged_offers,
      column: [:staged_offer_id, :side_id], primary_key: [:id, :side_id]
    # The key that does the work: an Exhibit rides out of the Case File of the
    # Team whose Offer it rides, and never out of the one across the table.
    add_foreign_key :staged_offer_exhibits, :case_file_documents,
      column: [:case_file_document_id, :side_id], primary_key: [:id, :side_id]

    # The mirror of `staged_offer_terms_need_an_unclosed_day`, and for the same
    # reason: revising the play touches no `staged_offers` row an INSERT trigger
    # would see, so the rule reaches the Day through the Offer it hangs off.
    execute <<~SQL
      CREATE TRIGGER staged_offer_exhibits_need_an_unclosed_day
      BEFORE INSERT ON staged_offer_exhibits
      WHEN EXISTS (
        SELECT 1 FROM staged_offers
        JOIN days ON days.id = staged_offers.day_id
        WHERE staged_offers.id = NEW.staged_offer_id
          AND days.closed_at IS NOT NULL
      )
      BEGIN
        SELECT RAISE(ABORT, 'staged_offer_exhibits_need_an_unclosed_day');
      END;
    SQL
  end

  # What an Exhibit is spent by. The row is the play: it names the Offer it rode,
  # the Day it landed on and the Case File document it was played from.
  #
  # It carries no relevance and no shift. Whether the play moved the Client is
  # whether a `client_shifts` row points back at this one — derived on read,
  # because a column beside it would be a second answer to the same question.
  def played_exhibits
    create_table :played_exhibits do |t|
      t.bigint :organization_id, null: false
      t.bigint :simulation_id, null: false
      t.bigint :side_id, null: false
      t.bigint :day_id, null: false
      t.bigint :committed_offer_id, null: false
      t.bigint :case_file_document_id, null: false

      t.timestamps
    end
    # An Exhibit plays exactly once, across the whole Simulation. The Case File
    # row is already unique per Side per authored document, so this one index
    # is the whole rule — a Team that attaches a spent Exhibit to a later Day's
    # Offer is refused by the seam and, past it, by this.
    add_index :played_exhibits, :case_file_document_id, unique: true
    add_index :played_exhibits, :committed_offer_id
    add_index :played_exhibits, [:side_id, :day_id]
    add_index :played_exhibits, :day_id
    add_foreign_key :played_exhibits, :sides,
      column: [:side_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :played_exhibits, :days,
      column: [:day_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :played_exhibits, :committed_offers,
      column: [:committed_offer_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :played_exhibits, :case_file_documents,
      column: [:case_file_document_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]

    # A play on a Day that has ended would be an Exhibit put in front of the
    # other Side after the Day it is recorded against was taken from the Team.
    execute <<~SQL
      CREATE TRIGGER played_exhibits_need_an_unclosed_day
      BEFORE INSERT ON played_exhibits
      WHEN EXISTS (
        SELECT 1 FROM days WHERE id = NEW.day_id AND closed_at IS NOT NULL
      )
      BEGIN
        SELECT RAISE(ABORT, 'played_exhibits_need_an_unclosed_day');
      END;
    SQL
  end

  # The ledger already takes the unfavorable discovery; this is the other way a
  # Client moves, and ADR 0003 is how the two are kept from landing twice over
  # one document. Both kinds key `source_ref` to the **receiving** Side's own
  # `case_file_documents` row — the row the finder filled, or the row service
  # wrote — so one document is one key, and this index refuses the second.
  #
  # Partial rather than plain, because `source_ref` carries no source table:
  # an Event's shift will point somewhere else, and a plain
  # `UNIQUE (side_id, source_ref)` would refuse an Event whose row id collided
  # with a Case File row's.
  def let_the_shift_ledger_take_a_played_exhibit
    remove_check_constraint :client_shifts, name: "client_shifts_source_kind_known"
    add_check_constraint :client_shifts,
      "source_kind IN ('unfavorable_discovery', 'exhibit_played')",
      name: "client_shifts_source_kind_known"
    add_index :client_shifts, [:side_id, :source_ref],
      unique: true,
      where: "source_kind IN ('unfavorable_discovery', 'exhibit_played')",
      name: ONE_MOVEMENT_PER_DOCUMENT_INDEX
  end

  def restore_the_shift_ledger_source_kinds
    if select_value("SELECT 1 FROM client_shifts WHERE source_kind = 'exhibit_played' LIMIT 1")
      raise ActiveRecord::IrreversibleMigration,
        "Exhibits have been played, and the shifts they wrote have no earlier kind to be"
    end

    remove_index :client_shifts, name: ONE_MOVEMENT_PER_DOCUMENT_INDEX
    remove_check_constraint :client_shifts, name: "client_shifts_source_kind_known"
    add_check_constraint :client_shifts, "source_kind IN ('unfavorable_discovery')",
      name: "client_shifts_source_kind_known"
  end
end
