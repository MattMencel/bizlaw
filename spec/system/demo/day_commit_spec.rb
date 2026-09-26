# frozen_string_literal: true

require "rails_helper"

# Committing the Day without an Offer (#396), in a browser: the block at the
# foot of the front, confirming in place, and focus landing where the result
# can be read.
RSpec.describe "committing the Day", type: :system do
  before { Demo::Seed.call }

  def block = find("section.day-commit")

  # The demo run's defendant sent its Offer on Day 3, which committed its Day,
  # so the player's commit is the second and ends it.
  describe "on the Day the player is handed" do
    before { visit "/demo/#{Demo::Seed::DEMO}" }

    it "sits at the foot of the front, after the Action slip" do
      headings = all("main h2").map(&:text)

      expect(headings.last).to match(/done for the day/i)
      expect(headings[-2]).to match(/slip/i)
    end

    it "states the consequence first when it opens in place" do
      block.click_button("Commit this Day")

      expect(block).to have_css("#day-commit-stub", text: /\AEnds the Day\./)
      expect(block).to have_button("Confirm")
    end

    it "commits nothing on Cancel" do
      block.click_button("Commit this Day")
      block.click_button("Cancel")

      expect(block).to have_no_button("Confirm")
      expect(page).to have_text("Day 3/")
    end

    it "closes the Day on Confirm and moves him to the next one" do
      block.click_button("Commit this Day")
      block.click_button("Confirm")

      expect(page).to have_text("Day 4/")
      expect(page).to have_css("#day-commit:focus")
    end

    it "is accessible with the confirmation open" do
      block.click_button("Commit this Day")

      expect(page).to be_axe_clean
    end
  end

  # The cold open is the run where nobody has committed, so the commit is the
  # first and the Day stays open.
  describe "the first Side to commit" do
    before { visit "/demo/#{Demo::Seed::COLD_OPEN}" }

    it "says the Day waits on the other Side" do
      block.click_button("Commit this Day")

      expect(block).to have_text("The Day ends once the other Side commits too.")
    end

    it "becomes the record, and focus lands on it" do
      block.click_button("Commit this Day")
      block.click_button("Confirm")

      expect(block).to have_text("Committed by Sam Ortega")
      expect(block).to have_no_button("Commit this Day")
      expect(page).to have_css("#day-commit:focus")
      expect(page).to have_text("Day 1/")
    end

    it "is accessible as a record" do
      block.click_button("Commit this Day")
      block.click_button("Confirm")
      expect(block).to have_text("Committed by Sam Ortega")

      expect(page).to be_axe_clean
    end
  end

  # A page that went stale while the Day closed under it. The press names the
  # Day it read, so the seam refuses it, and the sentence is wired to the
  # control on the page he lands on.
  describe "a Day that closed under the page" do
    it "says so on the block, wired to the control" do
      visit "/demo/#{Demo::Seed::DEMO}"
      Days::Close.call(Demo::Seed.simulation(Demo::Seed::DEMO).days.find_by!(ordinal: Demo::Seed::DEMO_DAY))

      block.click_button("Commit this Day")
      block.click_button("Confirm")

      expect(block).to have_css("#day-commit-refused", text: "This Day has closed.")
      expect(find_by_id("commit-the-day")["aria-describedby"]).to eq("day-commit-refused")
      expect(page).to have_css("#day-commit:focus")
    end
  end
end
