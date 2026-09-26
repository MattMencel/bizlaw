# frozen_string_literal: true

require "rails_helper"

# Committing the Day without an Offer: the seam between the Day commit block and
# `Days::Commit` (#396). One player's call, no Second — so what is under test is
# who it is attributed to, what the block reads before and after, what it leaves
# unlocked, and the refusals it carries back.
RSpec.describe "committing the Day", type: :request do
  before { Demo::Seed.call }

  let(:simulation) { Demo::Seed.simulation(Demo::Seed::DEMO) }
  let(:side) { simulation.plaintiff_side }
  let(:player) { User.find_by!(email: Demo::Seed::PLAYER_EMAIL) }
  let(:day) { simulation.days.find_by!(ordinal: Demo::Seed::DEMO_DAY) }
  let(:instructor) { User.find_by!(email: Demo::Seed::INSTRUCTOR_EMAIL) }
  let(:cold) { Demo::Seed.simulation(Demo::Seed::COLD_OPEN) }
  let(:first_day) { cold.days.find_by!(ordinal: 1) }

  def commit_the_day(run: Demo::Seed::DEMO, seat: nil, on: Demo::Seed::DEMO_DAY)
    post ["/demo/#{run}", seat, "day_commitments"].compact.join("/"), params: {day: on}
  end

  def block = inertia.props[:day_commit]

  # The cold open is the run where nobody has committed Day 1, so a commit there
  # is the first and leaves the Day open.
  describe "the first Side to commit" do
    it "records it against his Side, attributed to him, and leaves the Day open" do
      expect { commit_the_day(run: Demo::Seed::COLD_OPEN, on: 1) }
        .to change { cold.plaintiff_side.day_commitments.count }.by(1)

      expect(cold.plaintiff_side.day_commitments.sole.committed_by).to eq(player)
      expect(first_day.reload).to be_open
    end

    it "says, before he presses, that the Day waits on the other Side" do
      get "/demo/#{Demo::Seed::COLD_OPEN}"

      expect(block).to include(committed: false, closes_the_day: false, refusal: nil)
      expect(block[:stub]).to eq(I18n.t("reads.draft.day_commit.stub.waits"))
    end

    it "turns the block into the record once it lands" do
      commit_the_day(run: Demo::Seed::COLD_OPEN, on: 1)
      follow_redirect!

      expect(block).to include(committed: true, stub: nil, refusal: nil)
      expect(block[:record])
        .to eq(I18n.t("reads.draft.day_commit.committed_by", name: player.name))
    end

    # Committing locks nothing. A wrong "we're done" costs nothing, so the sheet
    # and the slip stay live until the Day actually closes.
    it "leaves his Side unlocked" do
      commit_the_day(run: Demo::Seed::COLD_OPEN, on: 1)
      follow_redirect!

      expect(inertia.props[:term_sheet][:writable]).to be(true)
      expect(inertia.props[:slip][:actions].find { |a| a[:kind] == "consult_client" })
        .to include(affordable: true)
    end

    it "puts it on his Docket, naming him" do
      commit_the_day(run: Demo::Seed::COLD_OPEN, on: 1)
      follow_redirect!

      line = inertia.props[:back][:docket][:entries].find { |e| e[:act] == "day_committed" }
      expect(line).to include(by: player.name, cost: nil, day: 1)
    end
  end

  # The demo run's defendant sent its Offer on Day 3, which committed its Day —
  # so the player's commit is the second, and the stub says so first.
  describe "the second Side to commit" do
    it "says it ends the Day before he presses" do
      get "/demo/#{Demo::Seed::DEMO}"

      expect(block).to include(closes_the_day: true)
      expect(block[:stub]).to eq(I18n.t("reads.draft.day_commit.stub.closes"))
      expect(block[:stub]).to start_with("Ends the Day.")
    end

    it "closes the Day and sends him to the next one" do
      expect { commit_the_day }.to change { day.reload.closed? }.from(false).to(true)

      follow_redirect!
      expect(inertia.props[:letterhead][:day]).to eq(Demo::Seed::DEMO_DAY + 1)
    end
  end

  # Sending an Offer already committed the Day, so the block is only the record,
  # and the Docket carries the send rather than a second line for the commit.
  describe "a Day his Team sent an Offer on" do
    before do
      Offers::Stage.call(side: cold.plaintiff_side, day: first_day, by: player, terms: {"apology" => nil})
      Offers::WaiveSecond.call(side: cold.plaintiff_side, day: first_day, by: instructor)
      Days::Command.apply(
        act: :commit_offer, side: cold.plaintiff_side, day: first_day, by: player, seconded_by: nil
      )
      get "/demo/#{Demo::Seed::COLD_OPEN}"
    end

    it "shows only the record" do
      expect(block).to include(committed: true, stub: nil, refusal: nil)
      expect(block[:record])
        .to eq(I18n.t("reads.draft.day_commit.committed_by", name: player.name))
    end

    it "puts no Day commit line on the Docket" do
      expect(inertia.props[:back][:docket][:entries].pluck(:act)).not_to include("day_committed")
    end
  end

  describe "what it refuses" do
    # A page that went stale while the Day closed under it. The press names the
    # Day it read, so the seam refuses it rather than committing tomorrow.
    it "refuses a Day that has closed, writes nothing, and says so on the block" do
      closed = simulation.days.find_by!(ordinal: 1)

      expect { commit_the_day(on: 1) }.not_to change(DayCommitment, :count)

      follow_redirect!
      expect(block[:refused]).to eq(I18n.t("reads.refusals.the_day_has_closed"))
      expect(closed).to be_closed
    end

    it "reads the refusal once" do
      commit_the_day(on: 1)
      follow_redirect!
      get "/demo/#{Demo::Seed::DEMO}"

      expect(block[:refused]).to be_nil
    end

    # The settled run renders the executed instrument, which prints no refusal,
    # and the shelf is cleared on the way past so it cannot print on the reset
    # run's first working draft.
    it "refuses a settled run and leaves nothing on the shelf" do
      Offers::WaiveSecond.call(side: side, day: day, by: instructor)
      Offers::Accept.call(
        offer: simulation.defendant_side.committed_offer_on(day), side: side, day: day, by: player
      )

      expect { commit_the_day }.not_to change(DayCommitment, :count)
      follow_redirect!
      expect(inertia.component).to eq("Demo/ExecutedInstrument")

      Demo::Seed.call
      get "/demo/#{Demo::Seed::DEMO}"
      expect(block[:refused]).to be_nil
    end
  end

  describe "what the address will not do" do
    it "does not know a Day off the calendar" do
      commit_the_day(on: 99)

      expect(response).to have_http_status(:not_found)
    end

    it "does not know a seat it did not lay down" do
      commit_the_day(seat: "whoever")

      expect(response).to have_http_status(:not_found)
    end

    # The Instructor is on no Side, so there is no Day of theirs to commit.
    it "refuses one taken from the Instructor's seat" do
      commit_the_day(seat: Demo::Seat::INSTRUCTOR)

      expect(response).to have_http_status(:not_found)
    end
  end
end
