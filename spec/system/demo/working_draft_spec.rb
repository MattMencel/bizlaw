# frozen_string_literal: true

require "rails_helper"

# The screen itself, in a browser, because Inertia renders there and because the
# claim ADR 0001 staked the whole stack on — that a first-timer can operate this
# unaided — is an accessibility claim before it is anything else.
RSpec.describe "the working draft", type: :system do
  before { Demo::Seed.call }

  describe "the Day the player is handed" do
    before { visit "/demo/#{Demo::Seed::DEMO}" }

    it "opens on the draft, with the Day's grammar named once" do
      expect(page).to have_text("You are looking at the draft.")
      expect(page).to have_text("Everything here is the case file")
    end

    it "carries the morning: what landed, what was served, what he started with" do
      expect(page).to have_text("The statement given to the trade press")
      expect(page).to have_text("Deposition of the plant supervisor")
      expect(page).to have_text("The termination letter")
    end

    it "puts their offer on the term sheet beside what his Client asked for" do
      expect(page).to have_text("$40,000")
      expect(page).to have_text("$250,000")
    end

    # The block is on the page before there is a draft to sign, because an empty
    # signature block is how the Day teaches that a commit needs a second hand.
    it "shows the countersignature block, with the execute control dead" do
      expect(page).to have_text(/countersigned by/i)
      expect(page).to have_button("Execute this draft", disabled: true)
    end

    it "prices every Action on the slip, whether or not today will cover it" do
      expect(page).to have_text("Consult the Client")
      expect(page).to have_text("Retain an expert")
      expect(page).to have_text(/8 preparation/i)
    end

    # The cost #315 accepted for this grammar: the record surfaces live behind a
    # gesture. That the gesture reaches them is the least this can prove.
    it "turns over to the Case File and the Docket" do
      click_button "Turn the page over"

      expect(page).to have_text(/what we know, and what we have done/i)
      expect(page).to have_text("The claimant's personnel file")
      expect(page).to have_text("Request documents")
    end

    it "is accessible" do
      expect(page).to be_axe_clean
    end

    it "is accessible on the back of the file too" do
      click_button "Turn the page over"

      expect(page).to be_axe_clean
    end
  end

  # Day 1, nothing spent: the only Day on which the empty states are the whole
  # of what a student reads, and the claim that they are the tutorial.
  describe "the cold open" do
    before { visit "/demo/#{Demo::Seed::COLD_OPEN}" }

    it "is not a blank page" do
      expect(page).to have_text("The other Side has put nothing in front of you.")
      expect(page).to have_text("an offer of nothing is a position somebody took")
      expect(page).to have_text("The termination letter")
    end

    it "still prices the whole Action Board" do
      expect(page).to have_text("Retain an expert")
      expect(page).to have_text(/5 preparation/i)
    end

    it "says what a Docket would hold" do
      click_button "Turn the page over"

      expect(page).to have_text("Nothing yet.")
    end

    it "is accessible" do
      expect(page).to be_axe_clean
    end
  end
end
