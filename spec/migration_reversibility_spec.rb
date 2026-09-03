# frozen_string_literal: true

require "rails_helper"

# ADR 0002 makes tenancy composite foreign keys, and Rails cannot auto-reverse
# `add_foreign_key` on one under SQLite: the key is part of the table definition
# rather than a separate object, so the reverse of a `change` migration calls
# `remove_foreign_key`, finds nothing to remove, and raises — after it has
# already dropped whatever came later, leaving the schema half-reverted.
#
# The failure is invisible until someone rolls back, which is exactly when they
# least want to discover it. This is a source check rather than a live rollback
# because running the real chain down and up would destroy the test database.
RSpec.describe "the migrations" do
  let(:migrations) { Rails.root.glob("db/migrate/*.rb") }

  it "are all present to be checked" do
    expect(migrations).not_to be_empty
  end

  it "write an explicit `down` wherever they add a composite foreign key" do
    offenders = migrations.select { |file|
      source = file.read
      source.include?("add_foreign_key") &&
        source.match?(/column: \[/) &&
        !source.match?(/^\s*def down\b/)
    }.map { |file| file.basename.to_s }

    expect(offenders).to be_empty
  end
end
