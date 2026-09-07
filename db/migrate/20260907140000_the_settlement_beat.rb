# frozen_string_literal: true

# What each Client says when the instrument is executed — the second Dialogue
# Node kind, keyed on which Side accepted. Two lines per Client: they took the
# other Side's number, or had their own taken. Different feelings about identical
# terms, which is the one dimension the act itself supplies.
#
# There are no variants and no seed. A settlement node is spoken exactly once, so
# a speak-count never advances and a variant would always resolve to the first —
# see ADR 0007.
#
# `case_clients` is `:authored`. Per the repo's rule for that tier both columns
# arrive `null: false` with **no default**: a Case Version authored before the
# settlement beat existed is not silently given a plausible line, it fails this
# migration and is re-imported.
class TheSettlementBeat < ActiveRecord::Migration[8.0]
  def up
    add_column :case_clients, :settlement_took_it, :text, null: false
    add_column :case_clients, :settlement_had_it_taken, :text, null: false
  end

  def down
    remove_column :case_clients, :settlement_had_it_taken
    remove_column :case_clients, :settlement_took_it
  end
end
