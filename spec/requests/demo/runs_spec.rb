# frozen_string_literal: true

require "rails_helper"

# The demo route resolves a run to a Side and a Day and hands the page one prop
# tree. What is under test is the resolution — the URL names a run and nothing
# else, so everything else about which Day a player sits down on is decided
# here.
RSpec.describe "the demo run", type: :request do
  before { Demo::Seed.call }

  describe "the Day the player is handed" do
    before { get "/demo/#{Demo::Seed::DEMO}" }

    it "renders the draft" do
      expect(response).to have_http_status(:ok)
      expect(inertia.component).to eq("Demo/WorkingDraft")
    end

    # #332: the player is the plaintiff, alone, and Day 3 is the earliest a
    # served Exhibit can exist. Neither is in the URL.
    it "sits him on the plaintiff's Side, on the first Day still open" do
      expect(inertia.props[:letterhead]).to include(role: Side::PLAINTIFF, day: 3)
    end

    it "hands him a Day already argued at" do
      expect(inertia.props[:front_matter][:served].pluck(:identifier))
        .to eq(["deposition_of_the_supervisor"])
      expect(inertia.props[:term_sheet][:tracks].find { |t| t[:term] == "money" }[:theirs])
        .to eq("amount" => "$40,000", "money" => true)
    end

    # He drew nothing overnight, so the block under the terms is blank — which
    # is the first thing the screen teaches.
    it "hands him an untouched draft over an unsigned block" do
      expect(inertia.props[:countersignature]).to eq(
        "drawn_by" => nil, "signed_by" => nil, "may_sign" => [],
        "executed" => false, "waived" => false
      )
      expect(inertia.props[:term_sheet][:ours_staged]).to be(false)
    end
  end

  describe "the cold open" do
    before { get "/demo/#{Demo::Seed::COLD_OPEN}" }

    it "opens on Day 1, with the empty states carrying the Day" do
      expect(inertia.props[:letterhead]).to include(day: 1)
      expect(inertia.props[:term_sheet][:empty_state]).to be_present
      expect(inertia.props[:back][:docket][:empty_state]).to be_present
    end

    # The case that separates the two questions. `Side#members` folds from
    # Attribution and nothing has been spent, so the roster is empty — but the
    # player is sitting there, and the letterhead asks who is reading rather
    # than who has acted. The seat knows him before he has done anything.
    it "names the player sitting at an empty ledger" do
      expect(inertia.props[:letterhead][:you]).to eq("Sam Ortega")
      expect(Demo::Seed.simulation(Demo::Seed::COLD_OPEN).plaintiff_side.members)
        .to be_empty
    end
  end

  # The second tab. It acts as a different person on the opposing Side, which is
  # where the Acceptance and the Instructor's waiver come from — there is no
  # second live player and no Instructor console.
  describe "the second tab" do
    before { get "/demo/#{Demo::Seed::DEMO}/#{Side::DEFENDANT}" }

    it "seats the other firm on the other Side of the same Day" do
      expect(inertia.props[:letterhead])
        .to include(role: Side::DEFENDANT, day: 3, you: "Dana Whitfield")
    end

    # It has already played its whole morning, which is what the player is
    # sitting down opposite.
    it "shows it the Offer it committed" do
      expect(inertia.props[:term_sheet][:tracks].find { |t| t[:term] == "money" }[:ours])
        .to eq("amount" => "$40,000", "money" => true)
    end
  end

  # One address, not two shapes. The bare form is what `rake demo:seed` prints
  # and what the player is handed; naming his seat resolves to the same page
  # rather than to a second one.
  it "answers the player's named seat as it answers the bare form" do
    get "/demo/#{Demo::Seed::DEMO}/#{Side::PLAINTIFF}"
    named = inertia.props

    get "/demo/#{Demo::Seed::DEMO}"

    expect(named).to eq(inertia.props)
  end

  # The Instructor is seated — `Offers::WaiveSecond` needs a `by:` and it exists
  # — but has no page. The Instructor console is out of scope for the whole
  # map, and the waiver's surface arrives with the control that grants it.
  it "has no page for the Instructor it seats" do
    expect(Demo::Seat.for(Demo::Seed.simulation(Demo::Seed::DEMO), Demo::Seat::INSTRUCTOR))
      .not_to be_seated

    get "/demo/#{Demo::Seed::DEMO}/#{Demo::Seat::INSTRUCTOR}"

    expect(response).to have_http_status(:not_found)
  end

  it "does not know a seat it did not lay down" do
    get "/demo/#{Demo::Seed::DEMO}/whoever"

    expect(response).to have_http_status(:not_found)
  end

  it "does not know a run it did not lay down" do
    get "/demo/whatever"

    expect(response).to have_http_status(:not_found)
  end
end
