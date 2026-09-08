# frozen_string_literal: true

# What a Case says about its Client's face, and the whole of what it says: an
# opaque seed. Named part choices are not authorable — `hair: shortCurly` does
# not survive the set being reskinned, and surviving the reskin is the point of
# having a set — so an author rerolls until they like the face, which is how
# this already works everywhere it exists. See ADR 0008.
#
# `case_clients` is `:authored`. Per the repo's rule for that tier the column
# arrives `null: false` with **no default**: a Case Version authored before the
# portrait existed is not silently given a plausible face, it fails this
# migration and is re-imported. A backfilled seed would be a real Client with a
# real face nobody chose.
#
# Uniqueness is not here and cannot be. The only collision anyone can ever see
# is the two Clients of one Case — Teams in different Simulations never meet,
# and a Team sees only its own Client — and two seeds colliding is two seeds
# composing to the same *identity*, which is a property of the part set rather
# than of the string. So it is a gate in `Cases::Import`.
class ThePortraitSeed < ActiveRecord::Migration[8.0]
  def up
    add_column :case_clients, :portrait_seed, :string, null: false
  end

  def down
    remove_column :case_clients, :portrait_seed
  end
end
