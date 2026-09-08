# frozen_string_literal: true

# What a Client says about where they stand, and the only read a Team ever gets
# on how far their own Client has moved. A Consult buys it; nothing else does.
#
# Two tables rather than one. `case_client_bands` holds the band's key and the
# **threshold** — the cumulative fraction of the bound at which the Client
# crosses into it — and the lines hang off it, because the threshold belongs to
# the band and not to each variant. A lines table is also where generated
# Dialogue Node variants land later without a reshape.
#
# The band itself is **stored nowhere**. It is folded on read from
# `client_shifts` as of the spend's own `created_at`, per ADR 0006: a band
# column on `docket_entries` would be a second materialized aggregate, and
# `day_budgets`' spent counters are the one ADR 0002 allows.
#
# Both tables are `:authored`. Per the repo's rule for that tier the threshold
# arrives `null: false` with **no default**: a defaulted edge is a silent
# import, and the point of an authored economy is that a Case omitting it fails
# loudly.
class TheReactionBand < ActiveRecord::Migration[8.0]
  # Two bands is engine — a third earns nothing a second does not — while the
  # edge between them is the Case's. The keys are also the two expressions a
  # Client is drawn in at a Consult, because the expression is derived from the
  # band by engine rule rather than authored per variant.
  BANDS = %w[firm ready].freeze

  def up
    create_table :case_client_bands do |t|
      t.bigint :case_version_id, null: false
      t.bigint :case_client_id, null: false
      t.string :key, null: false
      # The cumulative fraction of the bound at which the Client crosses into
      # this band, held as `client_shifts` holds the fractions it is compared
      # against. The lowest band sits at zero, so every fold lands in one.
      t.decimal :threshold, precision: 5, scale: 4, null: false

      t.timestamps

      t.check_constraint "key IN (#{BANDS.map { |band| "'#{band}'" }.join(", ")})",
        name: "case_client_bands_key_known"
      t.check_constraint "threshold >= 0 AND threshold <= 1",
        name: "case_client_bands_threshold_is_a_fraction_of_the_bound"
    end
    add_index :case_client_bands, [:case_client_id, :key], unique: true
    # The target of the composite key from the lines below.
    add_index :case_client_bands, [:id, :case_version_id], unique: true
    add_foreign_key :case_client_bands, :case_clients,
      column: [:case_client_id, :case_version_id], primary_key: [:id, :case_version_id]

    # The wording, one row per variant. A band carries several so that a Client
    # consulted on five Days does not repeat itself verbatim; which one is
    # spoken is `speak_count % variants`, and the order is the authored one.
    #
    # No ordinal column: the authored order is the insertion order, which is how
    # `case_documents` already keeps the order its Action yields them in.
    create_table :case_client_band_lines do |t|
      t.bigint :case_version_id, null: false
      t.bigint :case_client_band_id, null: false
      t.text :body, null: false

      t.timestamps
    end
    add_index :case_client_band_lines, :case_client_band_id
    add_foreign_key :case_client_band_lines, :case_client_bands,
      column: [:case_client_band_id, :case_version_id], primary_key: [:id, :case_version_id]
  end

  def down
    drop_table :case_client_band_lines
    drop_table :case_client_bands
  end
end
