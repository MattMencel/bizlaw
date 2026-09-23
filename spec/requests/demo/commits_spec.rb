# frozen_string_literal: true

require "rails_helper"

# Executing the draft: the seam between the countersignature block and
# `Days::Command`'s second act. What is under test is the gate, what the commit
# is attributed to, what it carries with it when it lands, and the one refusal
# that arrives at a page with nowhere left to print it.
RSpec.describe "executing the draft", type: :request do
  before { Demo::Seed.call }

  let(:simulation) { Demo::Seed.simulation(Demo::Seed::DEMO) }
  let(:side) { simulation.plaintiff_side }
  let(:player) { side.members.sole }
  let(:day) { simulation.days.find_by!(ordinal: Demo::Seed::DEMO_DAY) }
  let(:instructor) { User.find_by!(email: Demo::Seed::INSTRUCTOR_EMAIL) }

  def draw(on: day, of: side, by: nil)
    Offers::Stage.call(side: of, day: on, by: by || of.members.sole, terms: {"apology" => nil})
  end

  def execute(run: Demo::Seed::DEMO, seat: nil, on: Demo::Seed::DEMO_DAY)
    post ["/demo/#{run}", seat, "commits"].compact.join("/"), params: {day: on}
  end

  # The gate, from the address. Nothing a Team does clears it on a Side of one,
  # which is the beat the demo was built around — so the wire cannot be made to
  # clear it either.
  describe "before the Second is released" do
    it "refuses it and writes nothing" do
      draw

      expect { execute }.not_to change { side.committed_offers.count }
    end

    it "carries the engine's own sentence back to the block" do
      draw
      execute
      follow_redirect!

      expect(inertia.props[:countersignature][:refusal])
        .to eq(I18n.t("reads.refusals.the_offer_has_not_been_seconded"))
    end

    it "refuses a draft that does not exist at all" do
      expect { execute }.not_to change { side.committed_offers.count }

      follow_redirect!
      expect(inertia.props[:countersignature][:refusal])
        .to eq(I18n.t("reads.refusals.there_is_no_offer_on_the_table"))
    end
  end

  describe "once the Instructor has waived it" do
    before do
      draw
      Offers::WaiveSecond.call(side: side, day: day, by: instructor)
    end

    it "lands the Offer and charges the exchange half" do
      expect { execute }.to change { side.committed_offers.count }.by(1)

      expect(side.budget_on(day).remaining_in(DayBudget::EXCHANGE)).to eq(1)
    end

    # Attributed to the member who pressed it, and carrying **no seconder** —
    # a waiver substitutes for the Second and the Instructor never signs for a
    # Team, so there is nobody to name on that line.
    it "attributes it to him and names no seconder" do
      execute

      committed = side.committed_offer_on(day)
      expect(committed.staged_by).to eq(player)
      expect(committed.seconded_by).to be_nil
    end

    # The commit implies the Day commit, and the defendant committed Day 3 in the
    # seed — so this closes the Day and the route moves to the next one. That is
    # the engine being honest rather than a redirect going wrong.
    it "commits his Day with it, which closes the Day and opens the next" do
      expect { execute }.to change { day.reload.closed? }.from(false).to(true)

      follow_redirect!
      expect(inertia.props[:letterhead][:day]).to eq(Demo::Seed::DEMO_DAY + 1)
    end

    # Both acts survive on the record, and neither is a spend: the waiver is an
    # Instructor action with no cost, and the Docket is what `CONTEXT.md` § Second
    # says it owes them — visibility, rather than a silent change in what a
    # control will do.
    it "leaves the waiver and the execution on the Docket" do
      execute
      get "/demo/#{Demo::Seed::DEMO}/#{Side::PLAINTIFF}"

      acts = inertia.props[:back][:docket][:entries]
      expect(acts.pluck(:act)).to include("second_waived")
      expect(acts.find { |line| line[:act] == "second_waived" }).to include(cost: nil)
    end
  end

  # The hole this ticket's third shelf exists for. A teammate's commit landing
  # first makes the block a **record** — `execution` goes nil, and with it the
  # only thing that could have carried a sentence. Without a shelf of its own,
  # a reader who pressed Execute gets back an executed instrument he did not
  # execute and not one word about it.
  #
  # Exercised on the cold open, because it is the only run where a commit does
  # not also close the Day: the demo run's defendant has already committed Day
  # 3, so every commit there ends the Day and the second press is refused for
  # the Day rather than for the Offer.
  describe "a commit that a teammate's has already beaten" do
    let(:cold) { Demo::Seed.simulation(Demo::Seed::COLD_OPEN) }
    let(:first_day) { cold.days.find_by!(ordinal: 1) }

    it "says so on a block that has no price left to carry it" do
      draw(on: first_day, of: cold.plaintiff_side, by: User.find_by!(email: Demo::Seed::PLAYER_EMAIL))
      Offers::WaiveSecond.call(
        side: cold.plaintiff_side, day: first_day, by: instructor
      )

      execute(run: Demo::Seed::COLD_OPEN, on: 1)
      expect(first_day.reload).not_to be_closed

      execute(run: Demo::Seed::COLD_OPEN, on: 1)
      follow_redirect!

      expect(inertia.props[:countersignature][:executed]).to be(true)
      expect(inertia.props[:countersignature][:execution]).to be_nil
      expect(inertia.props[:countersignature][:refusal])
        .to eq(I18n.t("reads.refusals.an_offer_has_already_been_committed_today"))
    end
  end

  describe "what the address will not do" do
    it "does not know a Day off the calendar" do
      execute(on: 99)

      expect(response).to have_http_status(:not_found)
    end

    it "does not know a seat it did not lay down" do
      execute(seat: "whoever")

      expect(response).to have_http_status(:not_found)
    end

    # The Instructor is on no Side, so there is no draft of theirs to execute
    # and no half of theirs to charge.
    it "refuses one taken from the Instructor's seat" do
      execute(seat: Demo::Seat::INSTRUCTOR)

      expect(response).to have_http_status(:not_found)
    end
  end
end
