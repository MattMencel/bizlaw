# frozen_string_literal: true

require "rails_helper"

# Tenancy is composite foreign keys rather than a scope: a child carries its
# `organization_id` and points at its parent by `(parent_id, organization_id)`.
# These specs write the row the boundary is supposed to refuse, at the level
# below the models, and expect the database to raise.
RSpec.describe "the Organization boundary" do
  let(:other_organization) { an_organization(name: "Another University") }

  it "refuses a Simulation whose Section belongs to another Organization" do
    section = a_section
    case_version = a_case_version

    expect {
      Simulation.create!(
        section: section,
        case_version: case_version,
        organization_id: other_organization.id
      )
    }.to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "refuses a Side whose Simulation belongs to another Organization" do
    simulation = Simulation.create!(section: a_section, case_version: a_case_version)

    expect {
      Side.create!(
        simulation: simulation,
        role: "plaintiff",
        organization_id: other_organization.id
      )
    }.to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "refuses a Day whose Simulation belongs to another Organization" do
    simulation = a_simulation

    expect {
      Day.create!(
        simulation: simulation,
        ordinal: 99,
        in_fiction_date: Date.new(2026, 4, 1),
        organization_id: other_organization.id
      )
    }.to raise_error(ActiveRecord::InvalidForeignKey)
  end
end
