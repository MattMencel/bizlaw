# frozen_string_literal: true

# The authored side of the schema: a Case, its Versions, and the ordered
# in-fiction calendar a Version carries. Cases sit outside the Organization
# boundary — one Case backs Simulations in every Organization licensed to run
# it — so nothing here carries an `organization_id`.
class CreateAuthoredCaseTables < ActiveRecord::Migration[8.0]
  def change
    create_table :cases do |t|
      t.string :identifier, null: false
      t.string :name, null: false
      t.string :licence, null: false

      t.timestamps
    end
    add_index :cases, :identifier, unique: true

    # A published Version never changes again; a draft is the professor's
    # working copy. Published-ness is derived from `published_at`, never stored
    # as a status column.
    create_table :case_versions do |t|
      t.references :case, null: false, foreign_key: true
      t.string :version, null: false
      t.datetime :published_at

      t.timestamps
    end
    add_index :case_versions, [:case_id, :version], unique: true

    # The Day count is the length of this calendar rather than a column beside
    # it, so the two can never disagree.
    create_table :case_calendar_days do |t|
      t.references :case_version, null: false, foreign_key: true
      t.integer :ordinal, null: false
      t.date :in_fiction_date, null: false

      t.check_constraint "ordinal >= 1", name: "case_calendar_days_ordinal_positive"
    end
    add_index :case_calendar_days, [:case_version_id, :ordinal], unique: true
    add_index :case_calendar_days, [:case_version_id, :in_fiction_date], unique: true
  end
end
