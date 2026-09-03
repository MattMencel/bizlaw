# frozen_string_literal: true

require "rails_helper"

RSpec.describe Simulations::Create do
  it "writes every Day of the pinned calendar, in order, with its in-fiction date" do
    case_version = a_case_version(days: 10)

    simulation = described_class.call(section: a_section, case_version: case_version)

    expect(simulation.days.map(&:ordinal)).to eq((1..10).to_a)
    expect(simulation.days.map(&:in_fiction_date))
      .to eq(case_version.calendar_days.map(&:in_fiction_date))
  end

  it "writes exactly two Sides, plaintiff and defendant" do
    simulation = described_class.call(section: a_section, case_version: a_case_version)

    expect(simulation.sides.map(&:role)).to contain_exactly("plaintiff", "defendant")
    expect(simulation.plaintiff_side).to be_present
    expect(simulation.defendant_side).to be_present
  end

  it "pins each Side to the Case Version the Simulation runs on" do
    case_version = a_case_version

    simulation = described_class.call(section: a_section, case_version: case_version)

    expect(simulation.sides.map(&:case_version)).to all(eq(case_version))
  end

  it "opens Day 1, so the first Day arrives with both halves of each Side's Budget" do
    simulation = described_class.call(section: a_section, case_version: a_case_version)

    quotas = DayBudget.where(day: simulation.days.first)
    expect(quotas.count).to eq(2)
    expect(quotas.map(&:preparation_budget)).to all(eq(8))
    expect(quotas.map(&:exchange_budget)).to all(eq(2))
    expect(DayBudget.where(day: simulation.days.second)).to be_empty
  end

  it "refuses a draft Case Version" do
    draft = a_case_version(published: false)

    expect { described_class.call(section: a_section, case_version: draft) }
      .to raise_error(ActiveRecord::RecordInvalid, /draft/)
  end

  it "writes the whole calendar in one transaction, or none of it" do
    case_version = a_case_version(days: 10)
    unwritable = CaseCalendarDay.new(ordinal: 11, in_fiction_date: nil)
    allow(case_version).to receive(:calendar_days)
      .and_return(case_version.calendar_days.to_a + [unwritable])

    expect { described_class.call(section: a_section, case_version: case_version) }
      .to raise_error(ActiveRecord::RecordInvalid)
    expect(Simulation.count).to eq(0)
    expect(Day.count).to eq(0)
  end

  it "descends from the Section's Organization" do
    section = a_section

    simulation = described_class.call(section: section, case_version: a_case_version)

    expect(simulation.organization_id).to eq(section.organization_id)
    expect(simulation.days.map(&:organization_id)).to all(eq(section.organization_id))
    expect(simulation.sides.map(&:organization_id)).to all(eq(section.organization_id))
  end
end
