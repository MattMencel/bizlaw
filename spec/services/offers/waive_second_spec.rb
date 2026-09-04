# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offers::WaiveSecond do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:day) { simulation.days.first }
  let(:organization) { simulation.section.organization }
  let(:dana) { a_user(organization: organization, name: "Dana", email: "dana@wiu.edu") }
  let(:instructor) do
    a_user(organization: organization, name: "Professor Adeyemi", email: "adeyemi@wiu.edu")
  end

  def waive(on: day) = described_class.call(side: side, day: on, by: instructor)

  it "releases the gate for one Team on one Day" do
    waive

    expect(side.second_waived_on?(day)).to be(true)
  end

  it "does not persist into the next Day" do
    waive

    expect(side.second_waived_on?(simulation.days.second)).to be(false)
  end

  it "leaves the other Team's gate where it was" do
    waive

    expect(simulation.defendant_side.second_waived_on?(day)).to be(false)
  end

  it "lets a Team whose other members are absent commit what it staged" do
    offer = Offers::Stage.call(
      side: side, day: day, by: dana, terms: {"money" => 45_000_00}
    )
    waive

    expect(offer.eligible_seconders).to be_empty
    expect(offer.reload).to be_secondable
  end

  # Attribution would otherwise name someone who did not take the position.
  # The proof is structural rather than a query over an empty table: what the
  # waiver writes has nowhere to put a seconder, so no commit path built later
  # can read one out of it. It also leaves the Instructor outside the Team,
  # which is what keeps them off `eligible_seconders`.
  it "writes a row with nowhere for a seconder to go" do
    waiver = waive

    expect(waiver.granted_by).to eq(instructor)
    expect(SecondWaiver.column_names.grep(/second/)).to be_empty
    expect(side.members).not_to include(instructor)
  end

  it "is harmless to grant twice, keeping whoever granted it first" do
    first = waive
    again = described_class.call(side: side, day: day, by: dana)

    expect(again.id).to eq(first.id)
    expect(again.granted_by).to eq(instructor)
  end

  it "refuses a Day that has already closed" do
    Days::Close.call(day)

    expect { waive }.to raise_error(Offers::DayClosed)
  end
end
