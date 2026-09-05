# frozen_string_literal: true

# A played Exhibit comes out of the playing Team's own Case File, and rides that
# Team's own Offer. `staged_offer_exhibits` says so in its keys; this is the
# other half, and the same rule.
#
# Tenancy cannot express it. The two Sides share a Simulation and an
# Organization, so `(parent_id, simulation_id, organization_id)` on either
# parent would cheerfully take the row across the table — the key is true and
# the wrong thing is still sayable. `side_id`, which the row already carries, is
# the narrower key and gives tenancy for nothing, because a Side belongs to
# exactly one Simulation in exactly one Organization.
#
# `day_id` keeps its tenancy key: a Day belongs to the Simulation and not to
# either Side, so there is no narrower thing to say about it.
#
# Under SQLite a composite key lives inside the table definition, so each change
# below rebuilds the table — and a rebuilt table loses its triggers. The
# unclosed-Day guard is dropped and written back around the whole block rather
# than left to survive it.
class APlayedExhibitIsKeyedToTheSide < ActiveRecord::Migration[8.0]
  # Added by `ExhibitsRideTheOffer` for `played_exhibits` alone. Nothing reaches
  # the Case File by tenancy once this migration has run.
  CASE_FILE_DOCUMENT_TENANCY_INDEX =
    "index_case_file_documents_on_id_simulation_and_organization"

  def up
    # The target of the new key. `case_file_documents (id, side_id)` is already
    # there — `staged_offer_exhibits` reaches the Case File by it.
    add_index :committed_offers, [:id, :side_id], unique: true

    rekey_to_the_side(
      [:committed_offers, "committed_offer_id"],
      [:case_file_documents, "case_file_document_id"]
    )

    remove_index :case_file_documents, name: CASE_FILE_DOCUMENT_TENANCY_INDEX
  end

  def down
    add_index :case_file_documents, [:id, :simulation_id, :organization_id],
      unique: true, name: CASE_FILE_DOCUMENT_TENANCY_INDEX

    rekey_to_tenancy(
      [:committed_offers, "committed_offer_id"],
      [:case_file_documents, "case_file_document_id"]
    )

    remove_index :committed_offers, [:id, :side_id]
  end

  private

  # The columns naming an existing key are given as Strings rather than Symbols
  # on purpose: `remove_foreign_key` matches a composite one by comparing the
  # whole array's `to_s` against the one it read back out of the schema, and
  # `[:a, :b]` and `["a", "b"]` do not render the same. A Symbol here comes back
  # as "has no foreign key for", which reads like a missing key rather than a
  # missed match.
  def rekey_to_the_side(*parents)
    without_the_unclosed_day_trigger do
      parents.each do |table, column|
        remove_foreign_key :played_exhibits, table,
          column: [column, "simulation_id", "organization_id"]
        add_foreign_key :played_exhibits, table,
          column: [column, :side_id], primary_key: [:id, :side_id]
      end
    end
  end

  def rekey_to_tenancy(*parents)
    without_the_unclosed_day_trigger do
      parents.each do |table, column|
        remove_foreign_key :played_exhibits, table, column: [column, "side_id"]
        add_foreign_key :played_exhibits, table,
          column: [column, :simulation_id, :organization_id],
          primary_key: [:id, :simulation_id, :organization_id]
      end
    end
  end

  # Written back exactly as `ExhibitsRideTheOffer` first wrote it. A rewrite that
  # drifted from that would be a second definition of the same rule.
  def without_the_unclosed_day_trigger
    execute "DROP TRIGGER IF EXISTS played_exhibits_need_an_unclosed_day"
    yield
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
end
