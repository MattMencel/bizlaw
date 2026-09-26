# frozen_string_literal: true

require "rails_helper"

# The Instructor's instrument. What is under test is that it says the few things
# it is allowed to say and nothing else — a page that grew a Team's papers would
# be the console #312 ruled out, arriving by increment.
RSpec.describe Minute do
  include ActiveSupport::Testing::TimeHelpers

  before { Demo::Seed.call }

  let(:simulation) { Demo::Seed.simulation(Demo::Seed::DEMO) }
  let(:day) { simulation.days.find_by!(ordinal: Demo::Seed::DEMO_DAY) }
  let(:instructor) { User.find_by!(email: Demo::Seed::INSTRUCTOR_EMAIL) }

  def props(on: day) = described_class.for(simulation, day: on, you: instructor).to_props

  # The Section rather than the matter: an Instructor runs a Section and reads
  # this in one. The matter is on the Sides' own paper, where the dispute is.
  it "heads the minute with the Section they run" do
    expect(props[:letterhead]).to include(
      section: Demo::Seed::SECTION, day: Demo::Seed::DEMO_DAY, you: instructor.name
    )
  end

  # Plaintiff first, which is the order the caption of any matter is written in.
  # Alphabetical would put the defendant on top for no reason a reader could
  # name, and the row order the database returns is not a reason either.
  it "writes one line per Side, plaintiff first" do
    expect(props[:lines].pluck(:role)).to eq([Side::PLAINTIFF, Side::DEFENDANT])
  end

  # The one fact about a Team this page carries, and deliberately the thinnest
  # there is: granting blind is pressing a control with no way of knowing
  # whether it does anything.
  describe "what it says of a Team" do
    it "says nothing is drawn where nobody has taken a position" do
      expect(props[:lines].find { |line| line[:role] == Side::PLAINTIFF })
        .to include(drawn: false)
    end

    it "says a position is drawn once one is on the table, unexecuted" do
      side = simulation.plaintiff_side
      Offers::Stage.call(side: side, day: day, by: side.members.sole,
        terms: {"apology" => nil})

      expect(props[:lines].find { |line| line[:role] == Side::PLAINTIFF })
        .to include(drawn: true)
    end

    # The defendant executed its Day 3 draft in the seed, so it is past the gate
    # a waiver opens — which is a different thing from never having reached it,
    # and the line has to say so.
    it "says nothing is drawn where the Team has already executed today" do
      expect(props[:lines].find { |line| line[:role] == Side::DEFENDANT })
        .to include(drawn: false)
    end
  end

  describe "the waiver" do
    it "is ungranted before anyone grants one" do
      expect(props[:lines].pluck(:granted)).to eq([nil, nil])
    end

    # A record rather than a state. There is no revoking a waiver, so once this
    # is filled the line stops being a control and becomes the minute of
    # something that happened — which is why it names who and when.
    #
    # When is written on the server, so the minute reads the same to everyone
    # who opens it rather than in each browser's own clock.
    it "becomes a record naming who granted it, and when" do
      travel_to Time.zone.local(2026, 9, 25, 15, 4) do
        Offers::WaiveSecond.call(side: simulation.plaintiff_side, day: day, by: instructor)
      end

      granted = props[:lines].find { |line| line[:role] == Side::PLAINTIFF }[:granted]

      expect(granted[:by]).to eq(instructor.name)
      expect(granted[:minuted])
        .to eq("The second is waived for this Day. Granted by #{instructor.name}, Sep 25, 3:04 PM.")
    end

    # Granted to one Team, not to the Day. The other line is untouched, which is
    # the whole of what "for one Team for one Day" means on this surface.
    it "leaves the other Side's line alone" do
      Offers::WaiveSecond.call(side: simulation.plaintiff_side, day: day, by: instructor)

      expect(props[:lines].find { |line| line[:role] == Side::DEFENDANT }[:granted]).to be_nil
    end

    # Scoped to the Day it was granted on, and there is no read that could find
    # it from the next one.
    it "does not reach the next Day" do
      Offers::WaiveSecond.call(side: simulation.plaintiff_side, day: day, by: instructor)
      tomorrow = simulation.days.find_by!(ordinal: Demo::Seed::DEMO_DAY + 1)

      expect(props(on: tomorrow)[:lines].pluck(:granted)).to eq([nil, nil])
    end
  end

  # One vocabulary, however many surfaces name a rule: a Day that has closed says
  # the same sentence on the Instructor's minute as on a student's slip.
  describe "a refusal carried back" do
    it "marks the line it was refused on and leaves the other silent" do
      refused = described_class.for(
        simulation, day: day, you: instructor,
        refused: {"role" => Side::PLAINTIFF, "reason" => "the_day_has_closed"}
      ).to_props[:lines]

      expect(refused.find { |line| line[:role] == Side::PLAINTIFF }[:refusal])
        .to eq(I18n.t("reads.refusals.the_day_has_closed"))
      expect(refused.find { |line| line[:role] == Side::DEFENDANT }[:refusal]).to be_nil
    end
  end
end
