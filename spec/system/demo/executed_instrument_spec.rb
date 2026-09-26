# frozen_string_literal: true

require "rails_helper"

# The last beat, in a browser: the acceptance block that ends the run and the
# executed instrument the file rests on afterwards.
#
# `demo:seed` deliberately leaves Day 3 unplayed and `Seed.simulation` refuses a
# third run under the Organization, so the state this page needs cannot be
# seeded. It is driven through the seams instead — the pattern #373 established
# when the seed alone could not reach the register it had to look at.
RSpec.describe "the executed instrument", type: :system do
  before { Demo::Seed.call }

  let(:simulation) { Demo::Seed.simulation(Demo::Seed::DEMO) }
  let(:player_side) { simulation.plaintiff_side }
  let(:player) { player_side.members.sole }
  let(:instructor) { User.find_by!(email: Demo::Seed::INSTRUCTOR_EMAIL) }
  let(:demo_day) { simulation.days.find_by!(ordinal: Demo::Seed::DEMO_DAY) }

  # The demo's own order. He draws his position over theirs, the Instructor
  # releases his Second, and executing closes Day 3 and opens Day 4 — which is
  # the Day the defendant can take his paper on.
  def the_player_executes_his_draft
    Offers::Stage.call(side: player_side, day: demo_day, by: player,
      terms: {"money" => 150_000_00, "apology" => nil})
    Offers::WaiveSecond.call(side: player_side, day: demo_day, by: instructor)
    Days::Command.apply(act: :commit_offer, side: player_side, day: demo_day, by: player,
      seconded_by: nil)
  end

  # Their paper on his page. The seeded defendant Offer is standing on Day 3, so
  # this block is there from the cold start — dead, because his Side is one.
  describe "the acceptance block on the player's own page" do
    before { visit "/demo/#{Demo::Seed::DEMO}" }

    it "names their instrument without restating its terms" do
      expect(page).to have_text(/their offer, open on the table/i)
      expect(page).to have_text(/drawn by Dana Whitfield and committed on Day 3/)
    end

    # The covering line nothing on any surface read before #367. On Day 3 it is
    # still true; on Day 4 the same sentence is the register saying a deadline
    # has passed.
    it "prints their covering note" do
      expect(page).to have_text("Without prejudice. Open for acceptance today.")
    end

    # Dead for exactly the reason his commit is dead, and saying so — the rule
    # #363 set: `aria-disabled` keeps the control and its sentence in the tab
    # order together.
    it "holds the control dead while his Second stands, and says why" do
      expect(page).to have_css("button#accept-their-offer[aria-disabled='true']")
      expect(page)
        .to have_text("A teammate has to countersign before their offer can be accepted")
    end

    it "prints no price, because there is none" do
      expect(page).to have_css(".acceptance .price", text: "no cost")
    end

    it "is accessible" do
      expect(page).to be_axe_clean
    end
  end

  # From the defendant's tab, which is the seat the Acceptance was always going
  # to come from — and the one Side in the demo whose Second can be satisfied
  # rather than waived, because Dana and Ray have both acted.
  describe "taking the deal from the second tab" do
    before do
      the_player_executes_his_draft
      visit "/demo/#{Demo::Seed::DEMO}/defendant"
    end

    it "offers a live control and names the teammate who countersigns" do
      expect(page).to have_css("button#accept-their-offer:not([aria-disabled='true'])")

      click_button "Accept their offer"

      expect(page).to have_text("Ray Okonkwo countersigns")
      expect(page).to have_text("this closes Day 4 and settles the matter")
      expect(page).to have_text("there is nothing after it")
    end

    # Irreversible and free, which is the reason it confirms rather than in
    # spite of it: a single press would make the ending cost less than a
    # Consult.
    it "can be abandoned without settling anything" do
      click_button "Accept their offer"
      click_button "Cancel"

      expect(page).to have_no_text("this closes Day 4")
      expect(simulation.reload).not_to be_settled
    end

    it "settles the matter and becomes the executed instrument" do
      click_button "Accept their offer"
      click_button "Confirm accepting their offer"

      expect(page).to have_text("You are looking at the executed agreement.")
      expect(simulation.reload).to be_settled
    end

    # The act comes back to a different document, so the landing is that
    # document's own title rather than the control — which no longer exists.
    # It is also what puts a sighted reader at the top of a page that got much
    # shorter under a preserved scroll position.
    it "lands the reader on the executed sheet rather than where the block was" do
      click_button "Accept their offer"
      click_button "Confirm accepting their offer"

      expect(page).to have_css("h2#executed-terms")
      expect(page.evaluate_script("document.activeElement.id")).to eq("executed-terms")
    end
  end

  describe "once it has settled" do
    before do
      the_player_executes_his_draft
      Offers::Accept.call(
        offer: player_side.committed_offer_on(demo_day),
        side: simulation.defendant_side,
        day: simulation.days.find_by!(ordinal: 4),
        by: User.find_by!(email: Demo::Seed::DEFENDANT_LEAD_EMAIL),
        seconded_by: User.find_by!(email: Demo::Seed::DEFENDANT_SECOND_EMAIL)
      )
      visit "/demo/#{Demo::Seed::DEMO}"
    end

    it "prints the deal as one column, stamped in the fiction" do
      expect(page).to have_text("Terms of settlement")
      expect(page).to have_text("$150,000")
      expect(page).to have_css(".draft-mark.executed", text: /executed/i)
      expect(page).to have_css("table.terms caption", text: /Executed on Day 4/)
    end

    # The whole difference between this sheet and the working one. The redline
    # has nothing left to mark up, and the Client's aspiration beside the agreed
    # figure would be a Settlement Quality read arriving through the layout.
    it "carries neither the redline nor the Client's aspiration" do
      expect(page).to have_no_css("table.terms s")
      expect(page).to have_no_text("$250,000")
      expect(page).to have_no_text("Struck through, their last committed offer")
    end

    it "records both parties' hands, the waiver among them" do
      expect(page).to have_text(/for the plaintiff/i)
      expect(page).to have_text(/for the defendant/i)
      expect(page).to have_text("Sam Ortega")
      expect(page).to have_text("Ray Okonkwo")
      expect(page).to have_text(/countersignature waived by the instructor/i)
    end

    # A Team whose Offer was taken has no Morning Briefing to learn it from: no
    # Day opens after a settlement, so this page is how he finds out.
    it "gives the Client the last word, with no Reaction Band" do
      expect(page).to have_css("section .face svg")
      expect(page).to have_no_text(/reads firm/i)
      expect(page).to have_no_text(/reads ready/i)
    end

    # Nothing about a Day survives. There is no today to have a briefing, a
    # slip or a Consult on.
    it "has no briefing, no slip and nothing to write on" do
      expect(page).to have_no_text("Everything here is the case file")
      expect(page).to have_no_text("Consult the Client")
      expect(page).to have_no_css("input[type='checkbox']")
      expect(page).to have_no_css("button#execute-the-draft")
    end

    it "does not print a Day out of a calendar nobody will reach" do
      expect(page).to have_text("Settled ·")
      expect(page).to have_no_text(%r{Day 5/10})
    end

    it "still turns over to the Case File and the Docket" do
      click_button "Turn the page over"

      expect(page).to have_text(/what we know, and what we have done/i)
      expect(page).to have_text("Executed the draft")
    end

    it "is accessible" do
      expect(page).to be_axe_clean
    end

    it "is accessible on the back" do
      click_button "Turn the page over"

      expect(page).to be_axe_clean
    end

    # `CONTEXT.md` § Instructor keeps their powers over a running Day, and there
    # is no running Day. Without this branch the minute renders the first
    # unclosed Day — one that never opened — asserting the game is still going.
    it "leaves the Instructor's minute saying the Sides settled" do
      visit "/demo/#{Demo::Seed::DEMO}/#{Demo::Seat::INSTRUCTOR}"

      expect(page).to have_css("h3#closed", text: /\Asettled\z/i)
      expect(page).to have_text(/settled on Day 4/)
      expect(page).to have_no_css("button#waive-plaintiff")
      expect(page).to be_axe_clean
    end
  end
end
