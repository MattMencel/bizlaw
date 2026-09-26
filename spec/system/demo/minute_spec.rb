# frozen_string_literal: true

require "rails_helper"

# The Instructor's page in a browser. It is the professor's own surface during
# the demo, so it earns the same axe pass the students' does — the claim ADR
# 0001 staked the stack on is that this is operable unaided, and the person
# running the room is a reader like any other.
RSpec.describe "the Instructor's minute", type: :system do
  before { Demo::Seed.call }

  let(:simulation) { Demo::Seed.simulation(Demo::Seed::DEMO) }
  let(:side) { simulation.plaintiff_side }
  let(:day) { simulation.days.find_by!(ordinal: Demo::Seed::DEMO_DAY) }

  def minute(run: Demo::Seed::DEMO) = visit("/demo/#{run}/#{Demo::Seat::INSTRUCTOR}")

  def draw
    Offers::Stage.call(side: side, day: day, by: side.members.sole, terms: {"apology" => nil})
  end

  describe "the sheet" do
    before { minute }

    # Their paper, not a Team's: the Section in the letterhead, and one line per
    # Side rather than a file.
    it "is headed by the Section they run" do
      expect(page).to have_text(Demo::Seed::SECTION)
      expect(page).to have_text("Minute of the Instructor")
    end

    it "says what a waiver is before it offers one" do
      expect(page).to have_css("h3#waivers", text: /\Awaive a countersignature\z/i)
      expect(page).to have_text("without a teammate's countersignature")
      expect(page).to have_text("Cannot be undone.")
    end

    it "carries one line per Side" do
      expect(page).to have_button("Waive the second", count: 2)
    end

    # The obvious drawing and the wrong one. `CONTEXT.md` § Second: the
    # Instructor never Seconds on a Team's behalf, so there is nothing on this
    # instrument for them to sign.
    # The rubric says the word, because saying *nobody countersigns on a team's
    # behalf* is the point — what is ruled out is the mark, not the noun: no
    # ruled line, no hand, and no control that invites one.
    it "has no signature line anywhere on it" do
      expect(page).to have_no_css(".sig")
      expect(page).to have_no_css(".hand")
      expect(page).to have_no_css("button", text: /sign/i)
    end

    it "is accessible" do
      expect(page).to be_axe_clean
    end
  end

  # The one fact about a Team the minute carries. Granting blind is pressing a
  # control with no way of knowing whether it does anything.
  describe "what it says of a Team" do
    it "says nothing is drawn before anyone has drawn one" do
      minute

      expect(page).to have_text("No draft waiting", count: 2)
    end

    it "says a position is waiting once one is" do
      draw
      minute

      expect(page).to have_text("Draft waiting for a countersignature")
    end
  end

  # The beat: he grants it here, and the line stops being a control and becomes
  # the minute of something that happened.
  describe "granting one" do
    before do
      draw
      minute
    end

    it "records who granted it and when, in place of the control" do
      find("#waive-#{Side::PLAINTIFF}").click

      expect(page).to have_text("The second is waived for this Day.")
      expect(page).to have_text("Granted by Professor Adeyemi")
      expect(page).to have_no_css("#waive-#{Side::PLAINTIFF}")
    end

    # One Team for one Day: the other line is untouched, and it is still a
    # control.
    it "leaves the other Side's line alone" do
      find("#waive-#{Side::PLAINTIFF}").click

      expect(page).to have_text("The second is waived for this Day.", count: 1)
      expect(page).to have_css("#waive-#{Side::DEFENDANT}")
    end

    it "is accessible once one is granted" do
      find("#waive-#{Side::PLAINTIFF}").click

      expect(page).to have_text("Granted by Professor Adeyemi")
      expect(page).to be_axe_clean
    end
  end

  # A Day that has closed leaves the line standing and dead, because a minute
  # with a line missing is a minute of something that did not happen — and
  # `aria-disabled` rather than `disabled`, so the reason stays in the tab order
  # with the control, which is #363's rule.
  describe "a Day nobody is playing any more" do
    it "keeps the controls, refused and reachable" do
      # Played out rather than settled: `sitting_day` falls back to the last Day
      # when none is open, so a run with the calendar behind it still renders a
      # minute — and every line on it is dead.
      while (still_open = simulation.days.where(closed_at: nil).order(:ordinal).first)
        Days::Close.call(still_open)
      end
      minute

      expect(page).to have_text("this Day has closed")
      expect(find("#waive-#{Side::PLAINTIFF}")["aria-disabled"]).to eq("true")
    end
  end
end
