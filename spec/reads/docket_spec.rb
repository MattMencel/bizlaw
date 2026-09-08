# frozen_string_literal: true

require "rails_helper"

# What the Docket owes a teammate who was not in the room.
#
# The Second is never explained in advance. A student who stages an Offer holds
# a commit control that is present and disabled, naming the teammates who can
# second it — and the staging lands here, with Attribution, so it surfaces in a
# teammate's next Morning Briefing. A dead control in the hand teaches the rule
# that the door is never the gate; fixed copy elsewhere would not.
RSpec.describe Docket do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:day) { simulation.days.first }
  let(:organization) { simulation.section.organization }
  let(:dana) { a_user(organization: organization, name: "Dana", email: "dana@wiu.edu") }
  let(:instructor) do
    a_user(organization: organization, name: "Professor Adeyemi", email: "adeyemi@wiu.edu")
  end

  it "shows a spend with what it bought, its cost, its half and the Day it lands" do
    Days::Command.apply(
      act: :spend, side: side, day: day, by: dana, kind: CaseAction::DEPOSE_WITNESS
    )

    entry = side.docket.entries.sole

    expect(entry).to have_attributes(
      act: Docket::SPEND, by: dana, kind: CaseAction::DEPOSE_WITNESS,
      cost: 3, half: DayBudget::PREPARATION
    )
    expect(entry.lands_on_day.ordinal).to eq(3)
  end

  # The Client's beat is emphasis and never the sole carrier, and a Consult
  # yields no document — so this line is the only other place the band can land.
  it "carries the band on the one Action that buys a read rather than paper" do
    Days::Command.apply(
      act: :spend, side: side, day: day, by: dana, kind: CaseAction::CONSULT_CLIENT
    )

    expect(side.docket.entries.sole)
      .to have_attributes(kind: CaseAction::CONSULT_CLIENT, band: CaseClientBand::FIRM)
  end

  # A band is what a Consult was charged for. Nothing else may carry one, and a
  # Docket that re-read live would be a free band ticker.
  it "carries no band on a spend that bought paper" do
    Days::Command.apply(
      act: :spend, side: side, day: day, by: dana, kind: CaseAction::REQUEST_DOCUMENTS
    )

    expect(side.docket.entries.sole.band).to be_nil
  end

  it "keeps the band a Consult read once the Client has moved since" do
    Days::Command.apply(
      act: :spend, side: side, day: day, by: dana, kind: CaseAction::CONSULT_CLIENT
    )
    side.client_shifts.create!(
      day: day, source_kind: ClientShift::UNFAVORABLE_DISCOVERY,
      source_ref: 1, requested_fraction: 0.9
    )

    expect(side.docket.entries.sole.band).to eq(CaseClientBand::FIRM)
  end

  it "shows the staging with Attribution, and no cost against it" do
    Offers::Stage.call(side: side, day: day, by: dana, terms: {"money" => 45_000_00})

    entry = side.docket.entries.sole

    expect(entry).to have_attributes(
      act: Docket::OFFER_STAGED, by: dana, kind: nil, cost: nil, half: nil, band: nil
    )
    expect(entry).not_to be_spend
  end

  # Revising costs nothing and adds no line, and the line that is there keeps
  # naming the member who put the Offer on the table — which is the member a
  # teammate reading this is being asked to second for.
  it "adds no line for a revision, and does not move its Attribution" do
    ravi = a_user(organization: organization, name: "Ravi", email: "ravi@wiu.edu")
    Offers::Stage.call(side: side, day: day, by: dana, terms: {"money" => 45_000_00})
    Offers::Stage.call(side: side, day: day, by: ravi, terms: {"money" => 40_000_00})

    expect(side.docket.entries.map(&:by)).to eq([dana])
  end

  it "puts the Instructor's waiver on the record as an Instructor action" do
    Offers::WaiveSecond.call(side: side, day: day, by: instructor)

    expect(side.docket.entries.sole).to have_attributes(
      act: Docket::SECOND_WAIVED, by: instructor, cost: nil
    )
    expect(side.docket.entries.sole).to be_instructor_action
  end

  it "reads in the order it was written" do
    Days::Command.apply(
      act: :spend, side: side, day: day, by: dana, kind: CaseAction::CONSULT_CLIENT
    )
    Offers::Stage.call(side: side, day: day, by: dana, terms: {"money" => 45_000_00})
    Offers::WaiveSecond.call(side: side, day: day, by: instructor)

    expect(side.docket.entries.map(&:act))
      .to eq([Docket::SPEND, Docket::OFFER_STAGED, Docket::SECOND_WAIVED])
  end

  it "narrows to one Day when asked for one" do
    Offers::Stage.call(side: side, day: day, by: dana, terms: {"money" => 45_000_00})

    expect(side.docket(day: simulation.days.second).entries).to be_empty
  end

  it "shows the other Team nothing of this one's" do
    Offers::Stage.call(side: side, day: day, by: dana, terms: {"money" => 45_000_00})

    expect(simulation.defendant_side.docket.entries).to be_empty
  end

  # The empty state is the tutorial: an empty Docket says what a Docket would
  # hold. There is no first-run pass and no per-student progress flag, so this
  # sentence does the work a tour would otherwise do.
  describe "the empty state" do
    it "describes what a Docket would hold" do
      expect(side.docket).to be_empty
      expect(side.docket.empty_state).to include("what it cost", "the Day its result arrives")
    end

    it "says nothing once there is something to read" do
      Offers::Stage.call(side: side, day: day, by: dana, terms: {"money" => 45_000_00})

      expect(side.docket.empty_state).to be_nil
    end

    # A Docket narrowed to a Day nothing happened on is as empty as a new one,
    # and says the same thing.
    it "speaks for a Day the Team did nothing on" do
      Offers::Stage.call(side: side, day: day, by: dana, terms: {"money" => 45_000_00})

      expect(side.docket(day: simulation.days.second).empty_state).to be_present
    end
  end
end
