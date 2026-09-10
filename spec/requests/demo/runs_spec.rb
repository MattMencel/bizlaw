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

    # `Side#members` folds from Attribution, and nothing has been spent. There
    # is no name to put on the letterhead and none is invented.
    it "names nobody" do
      expect(inertia.props[:letterhead][:you]).to be_nil
    end
  end

  it "does not know a run it did not lay down" do
    get "/demo/whatever"

    expect(response).to have_http_status(:not_found)
  end
end
