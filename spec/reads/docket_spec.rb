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

  it "shows a spend with its cost, its half and the Day its result lands" do
    Days::Command.apply(
      act: :spend, side: side, day: day, by: dana, kind: CaseAction::DEPOSE_WITNESS
    )

    entry = side.docket.sole

    expect(entry).to have_attributes(
      act: Docket::SPEND, by: dana, cost: 3, half: DayBudget::PREPARATION
    )
    expect(entry.lands_on_day.ordinal).to eq(3)
  end

  it "shows the staging with Attribution, and no cost against it" do
    Offers::Stage.call(side: side, day: day, by: dana, terms: {"money" => 45_000_00})

    entry = side.docket.sole

    expect(entry).to have_attributes(act: Docket::OFFER_STAGED, by: dana, cost: nil, half: nil)
    expect(entry).not_to be_spend
  end

  # Revising costs nothing and adds no line. The Attribution moves, because
  # whoever wrote the position now on the table is who a teammate reading this
  # would be seconding.
  it "adds no line for a revision" do
    ravi = a_user(organization: organization, name: "Ravi", email: "ravi@wiu.edu")
    Offers::Stage.call(side: side, day: day, by: dana, terms: {"money" => 45_000_00})
    Offers::Stage.call(side: side, day: day, by: ravi, terms: {"money" => 40_000_00})

    expect(side.docket.map(&:by)).to eq([ravi])
  end

  it "puts the Instructor's waiver on the record as an Instructor action" do
    Offers::WaiveSecond.call(side: side, day: day, by: instructor)

    expect(side.docket.sole).to have_attributes(
      act: Docket::SECOND_WAIVED, by: instructor, cost: nil
    )
    expect(side.docket.sole).to be_instructor_action
  end

  it "reads in the order it was written" do
    Days::Command.apply(
      act: :spend, side: side, day: day, by: dana, kind: CaseAction::CONSULT_CLIENT
    )
    Offers::Stage.call(side: side, day: day, by: dana, terms: {"money" => 45_000_00})
    Offers::WaiveSecond.call(side: side, day: day, by: instructor)

    expect(side.docket.map(&:act))
      .to eq([Docket::SPEND, Docket::OFFER_STAGED, Docket::SECOND_WAIVED])
  end

  it "narrows to one Day when asked for one" do
    Offers::Stage.call(side: side, day: day, by: dana, terms: {"money" => 45_000_00})

    expect(side.docket(day: simulation.days.second)).to be_empty
  end

  it "shows the other Team nothing of this one's" do
    Offers::Stage.call(side: side, day: day, by: dana, terms: {"money" => 45_000_00})

    expect(simulation.defendant_side.docket).to be_empty
  end
end
