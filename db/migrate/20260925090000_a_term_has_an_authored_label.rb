# frozen_string_literal: true

# What a Term reads as, authored beside its key. The engine humanized the key
# until now, which printed `nda` as *Nda*: a key is an identifier the Case names
# a Term by, and the words a student reads are the author's to choose.
#
# `:authored`, so `null: false` with **no default**. A Case Version that
# predates the column fails this migration and is re-imported, rather than being
# given a label nobody wrote.
class ATermHasAnAuthoredLabel < ActiveRecord::Migration[8.0]
  def change
    add_column :case_terms, :label, :string, null: false
  end
end
