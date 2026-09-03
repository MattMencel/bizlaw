# frozen_string_literal: true

# The run's shape: the Organization boundary, the Section under it, a Simulation
# pinned to a Case Version, its two Sides and its whole Day calendar.
#
# Tenancy is composite foreign keys. Every table below carries its
# `organization_id` and points at its parent by `(parent_id, organization_id)`,
# so a child in one Organization cannot reference a parent in another — the
# boundary is a schema shape rather than a scope someone has to remember.
class CreateSimulationSkeleton < ActiveRecord::Migration[8.0]
  def up
    create_table :organizations do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_table :sections do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end
    # The target of the composite foreign keys below.
    add_index :sections, [:id, :organization_id], unique: true

    create_table :simulations do |t|
      t.bigint :organization_id, null: false
      t.bigint :section_id, null: false
      t.references :case_version, null: false, foreign_key: true

      t.timestamps
    end
    add_index :simulations, [:section_id, :organization_id]
    add_index :simulations, [:id, :organization_id], unique: true
    add_foreign_key :simulations, :sections,
      column: [:section_id, :organization_id], primary_key: [:id, :organization_id]

    # Exactly two per Simulation. The unique index caps it at one of each role
    # and the CHECK caps the roles themselves; writing both is one transaction.
    create_table :sides do |t|
      t.bigint :organization_id, null: false
      t.bigint :simulation_id, null: false
      t.string :role, null: false

      t.timestamps

      t.check_constraint "role IN ('plaintiff', 'defendant')", name: "sides_role_known"
    end
    add_index :sides, [:simulation_id, :role], unique: true
    add_index :sides, [:id, :organization_id], unique: true
    add_foreign_key :sides, :simulations,
      column: [:simulation_id, :organization_id], primary_key: [:id, :organization_id]

    # Whether a Day is open is derived from `closed_at`. There is no status
    # column here or on any other table in this migration.
    create_table :days do |t|
      t.bigint :organization_id, null: false
      t.bigint :simulation_id, null: false
      t.integer :ordinal, null: false
      t.date :in_fiction_date, null: false
      t.datetime :closed_at

      t.timestamps

      t.check_constraint "ordinal >= 1", name: "days_ordinal_positive"
    end
    add_index :days, [:simulation_id, :ordinal], unique: true
    add_index :days, [:simulation_id, :in_fiction_date], unique: true
    add_index :days, [:id, :organization_id], unique: true
    add_foreign_key :days, :simulations,
      column: [:simulation_id, :organization_id], primary_key: [:id, :organization_id]
  end

  # Written out rather than left to `change`, because Rails cannot auto-reverse
  # `add_foreign_key` on a composite key under SQLite. The key is part of the
  # table definition rather than a separate object, so the reverse of the
  # migration calls `remove_foreign_key`, finds nothing to remove, and raises
  # `Table 'days' has no foreign key for simulations` — leaving the schema
  # half-reverted. Dropping each table takes its keys with it; children first,
  # so nothing is dropped out from under a key still pointing at it.
  def down
    drop_table :days
    drop_table :sides
    drop_table :simulations
    drop_table :sections
    drop_table :organizations
  end
end
