# frozen_string_literal: true

# What makes two runs of one Case differ. `CONTEXT.md` under *Dialogue Node*
# has a Consult's variants chosen by the Simulation seed *and* the speak count;
# there was no seed, so every Team on a Case heard its Client's lines in one
# fixed order — invisible with one player, visible the moment a Section runs
# two Teams.
#
# `simulations` is `:skeleton`, and the column arrives `null: false` with **no
# default** for the reason an authored one does: a run already in flight cannot
# be handed a plausible seed after the fact, because a seed is only meaningful
# from the moment its first line is spoken under it. There is no roster and no
# live Section yet, so the loud failure this would produce is a development
# database that gets rebuilt.
#
# `Simulations::Create` is the writer — the same one seam that lays out the
# Sides and the calendar — rather than a database default, which would make the
# seam not the writer.
class TheSimulationSeed < ActiveRecord::Migration[8.0]
  def up
    add_column :simulations, :seed, :string, null: false

    # Immutability is the whole property. A Consult's memo is re-readable
    # forever and has to read back the variant the Client actually spoke, so a
    # seed that moved would rewrite history a Docket line already claims — and
    # nothing about the rewrite would be visible, because a memo stores no
    # wording to disagree with.
    #
    # `attr_readonly` covers the ordinary path. This is what holds an UPDATE
    # that skips the model, which is ADR 0002's rule: an invariant lives in the
    # database wherever it fits in one, and this one fits in one. `IS NOT`
    # rather than `<>` so a comparison against NULL is still a change.
    #
    # `INSERT OR REPLACE` would get past it — SQLite implements that as a delete
    # and an insert, and no UPDATE trigger sees it. A `BEFORE DELETE` refusal is
    # not the answer, because Retention hard-deletes a run's skeleton on its own
    # clock and would trip over it.
    execute(<<~SQL)
      CREATE TRIGGER simulations_seed_is_written_once
      BEFORE UPDATE OF seed ON simulations
      WHEN NEW.seed IS NOT OLD.seed
      BEGIN
        SELECT RAISE(ABORT, 'simulations_seed_is_written_once');
      END;
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS simulations_seed_is_written_once;"
    remove_column :simulations, :seed
  end
end
