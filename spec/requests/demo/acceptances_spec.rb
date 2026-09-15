# frozen_string_literal: true

require "rails_helper"

# Taking the other Side's deal: the seam between the acceptance block and
# `Offers::Accept`, and the last act in the game. What is under test is which
# instrument the wire names, the gate, and what the page becomes afterwards —
# because afterwards there is nowhere left to go.
RSpec.describe "accepting their offer", type: :request do
  before { Demo::Seed.call }

  let(:simulation) { Demo::Seed.simulation(Demo::Seed::DEMO) }
  let(:player_side) { simulation.plaintiff_side }
  let(:player) { player_side.members.sole }
  let(:dana) { User.find_by!(email: Demo::Seed::DEFENDANT_LEAD_EMAIL) }
  let(:ray) { User.find_by!(email: Demo::Seed::DEFENDANT_SECOND_EMAIL) }
  let(:instructor) { User.find_by!(email: Demo::Seed::INSTRUCTOR_EMAIL) }
  let(:demo_day) { simulation.days.find_by!(ordinal: Demo::Seed::DEMO_DAY) }

  # The demo's own flow. The defendant's Day 3 Offer is seeded and standing; the
  # player draws his own over it, the Instructor releases his Second, and
  # executing closes Day 3 and opens Day 4 — which is the Day the defendant can
  # take his paper on.
  def the_player_executes_his_draft
    Offers::Stage.call(side: player_side, day: demo_day, by: player,
      terms: {"money" => 150_000_00})
    Offers::WaiveSecond.call(side: player_side, day: demo_day, by: instructor)
    Days::Command.apply(act: :commit_offer, side: player_side, day: demo_day, by: player,
      seconded_by: nil)
  end

  # The bare form is the player's, per #360, and the named one is the second
  # tab's. Both are built here the way `SeatedController` writes them, so a
  # nil seat is his address rather than an empty segment.
  def accept(seat: "defendant", on: 4, committed_on: Demo::Seed::DEMO_DAY, seconded_by: nil)
    post ["/demo/#{Demo::Seed::DEMO}", seat, "acceptances"].compact.join("/"),
      params: {day: on, committed_on: committed_on, seconded_by: seconded_by}
  end

  describe "the wire" do
    before { the_player_executes_his_draft }

    # Named by the Day their Offer landed on rather than by a row id: unique per
    # Side, and stable across the reset that moves every id underneath it.
    it "takes the instrument the named Day carries" do
      expect { accept(seconded_by: ray.email) }
        .to change { simulation.reload.settled? }.from(false).to(true)

      expect(OfferAcceptance.sole.committed_offer)
        .to eq(player_side.committed_offer_on(demo_day))
    end

    it "attributes it to the member who took it, over the teammate who signed" do
      accept(seconded_by: ray.email)

      expect(OfferAcceptance.sole).to have_attributes(accepted_by: dana, seconded_by: ray)
    end

    it "does not know a Day the other Side committed nothing on" do
      accept(committed_on: 1, seconded_by: ray.email)

      expect(response).to have_http_status(:not_found)
    end

    it "does not know a seconder who is not on the Team" do
      accept(seconded_by: player.email)

      expect(response).to have_http_status(:not_found)
    end
  end

  # The one act in the demo where the Second is satisfied rather than waived.
  describe "the gate" do
    before { the_player_executes_his_draft }

    it "refuses an Acceptance nobody countersigned, and writes nothing" do
      expect { accept }.not_to change { OfferAcceptance.count }
    end

    it "carries the engine's own sentence back to the block" do
      accept
      follow_redirect!

      expect(inertia.props[:acceptance][:refused])
        .to eq(I18n.t("reads.refusals.the_acceptance_has_not_been_seconded"))
    end
  end

  # The player could take the defendant's seeded $40,000 instead of countering.
  # His Side is one member, so it is refused for exactly the reason his commit
  # is — and the Instructor's waiver releases it for the same reason, because a
  # waiver is granted to a Side for a Day and not to an act.
  describe "from the player's own seat" do
    def take_theirs
      accept(seat: nil, on: Demo::Seed::DEMO_DAY, committed_on: Demo::Seed::DEMO_DAY)
    end

    it "is refused while his Second stands" do
      expect { take_theirs }.not_to change { OfferAcceptance.count }

      follow_redirect!
      expect(inertia.props[:acceptance][:refused])
        .to eq(I18n.t("reads.refusals.the_acceptance_has_not_been_seconded"))
    end

    it "lands once the Instructor has released it, ending the run on Day 3" do
      Offers::WaiveSecond.call(side: player_side, day: demo_day, by: instructor)

      expect { take_theirs }.to change { simulation.reload.settled? }.from(false).to(true)
      expect(simulation.days.find_by!(ordinal: 4).budgets).to be_empty
    end
  end

  describe "once it has settled" do
    before do
      the_player_executes_his_draft
      accept(seconded_by: ray.email)
    end

    # Ordering is load-bearing in `Offers::Accept`: the row is written before
    # `Days::Close` runs, so `settled?` is already true when the close decides
    # whether to open the following Day.
    it "closes the Day it was taken on and opens nothing after it" do
      expect(simulation.days.find_by!(ordinal: 4)).to be_closed
      expect(simulation.days.find_by!(ordinal: 5).budgets).to be_empty
    end

    it "renders the executed instrument on both seats' own address" do
      get "/demo/#{Demo::Seed::DEMO}"
      expect(inertia.component).to eq("Demo/ExecutedInstrument")

      get "/demo/#{Demo::Seed::DEMO}/defendant"
      expect(inertia.component).to eq("Demo/ExecutedInstrument")
    end

    # The defect this branch exists for. `sitting_day` answers the first
    # unclosed Day, and after a settlement that is a Day `Simulations::Create`
    # laid down and `Days::Open` never reached — so without the branch the page
    # renders a live tomorrow with nil budgets and every Action refused.
    it "asks for no Day at all" do
      get "/demo/#{Demo::Seed::DEMO}"

      expect(inertia.props[:letterhead]).not_to have_key(:day)
      expect(inertia.props.keys.map(&:to_s) - ["errors"])
        .to match_array(%w[letterhead terms signatures stamp beat back])
    end

    it "prints both parties' signatures, the waiver among them" do
      get "/demo/#{Demo::Seed::DEMO}"

      # String keys: a prop tree comes back through Inertia as JSON, and only
      # the top level is symbolized.
      expect(inertia.props[:signatures]).to eq([
        {"role" => Side::PLAINTIFF, "signed_by" => player.name,
         "seconded_by" => nil, "waived" => true},
        {"role" => Side::DEFENDANT, "signed_by" => dana.name,
         "seconded_by" => ray.name, "waived" => false}
      ])
    end

    # `CONTEXT.md` § Instructor keeps their powers over a running Simulation
    # deliberately few, and a settled run has no running Day for one to reach.
    it "leaves the Instructor's minute saying the matter is closed" do
      get "/demo/#{Demo::Seed::DEMO}/#{Demo::Seat::INSTRUCTOR}"

      expect(inertia.props[:settled]).to include(day: 4)
      expect(inertia.props[:lines]).to be_empty
    end

    it "refuses a second Acceptance rather than faulting" do
      accept(seconded_by: ray.email)
      follow_redirect!

      expect(inertia.component).to eq("Demo/ExecutedInstrument")
    end
  end
end
