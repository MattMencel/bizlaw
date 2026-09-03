# frozen_string_literal: true

require "rails_helper"

# Tenancy is composite foreign keys rather than a scope: a child carries its
# tenancy columns and points at its parent by them. For the run's own tables
# that key is `(parent_id, simulation_id, organization_id)`, because a Section
# runs many concurrent Simulations inside one Organization and the Organization
# alone would let a row pair a Side from one run with a Day from another.
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

  describe "two Simulations of one Case under one Section" do
    let(:section) { a_section }
    let(:case_version) { a_case_version }
    let(:mine) { a_simulation(section: section, case_version: case_version) }
    let(:theirs) { a_simulation(section: section, case_version: case_version) }

    it "refuses a Budget pairing a Side with a Day of the other Simulation" do
      expect {
        DayBudget.create!(side: mine.plaintiff_side, day: theirs.days.first,
          preparation_budget: 8, exchange_budget: 2)
      }.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "refuses a Day commitment pairing a Side with a Day of the other Simulation" do
      expect {
        DayCommitment.create!(
          side: mine.plaintiff_side, day: theirs.days.first,
          committed_by: a_user(organization: section.organization)
        )
      }.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "refuses a Docket row whose result lands on a Day of the other Simulation" do
      day = mine.days.first

      expect {
        mine.plaintiff_side.docket_entries.create!(
          day: day,
          lands_on_day: theirs.days.first,
          spent_by: a_user(organization: section.organization),
          case_action: case_version.actions.first,
          cost: 1,
          half: DayBudget::PREPARATION
        )
      }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  it "refuses a Day commitment attributed to a member of another Organization" do
    simulation = a_simulation

    expect {
      DayCommitment.create!(
        side: simulation.plaintiff_side,
        day: simulation.days.first,
        committed_by: a_user(organization: other_organization, email: "elsewhere@example.edu")
      )
    }.to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "refuses a Docket row attributed to a member of another Organization" do
    simulation = a_simulation
    day = simulation.days.first

    expect {
      simulation.plaintiff_side.docket_entries.create!(
        day: day,
        lands_on_day: day,
        spent_by: a_user(organization: other_organization, email: "elsewhere@example.edu"),
        case_action: simulation.case_version.actions.first,
        cost: 1,
        half: DayBudget::PREPARATION
      )
    }.to raise_error(ActiveRecord::InvalidForeignKey)
  end
end
