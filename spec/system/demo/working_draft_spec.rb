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

  # The first act in the game. Three legs across one Inertia round trip — the
  # price offered on the slip, the confirmation read from the same quote, and
  # the charge — and the whole of it has to read as paper rather than as a
  # browser dialog.
  describe "spending an Action" do
    before { visit "/demo/#{Demo::Seed::DEMO}" }

    def slip_line(label) = find("li.slip", text: label)

    it "opens the price in place, against what the half has left" do
      slip_line("Consult the Client").click_button("Spend")

      expect(page).to have_text("1 preparation · 7 preparation left after · lands today")
      expect(page).to have_button("Confirm")
    end

    # The argument for confirming on the line rather than over the sheet: the
    # other five prices are what makes this one a trade-off.
    it "leaves the rest of the menu on the page while he decides" do
      slip_line("Consult the Client").click_button("Spend")

      expect(page).to have_text("Retain an expert")
      expect(page).to have_text("Depose a witness")
    end

    it "opens one stub at a time" do
      slip_line("Consult the Client").click_button("Spend")
      slip_line("Retain an expert").click_button("Spend")

      expect(page).to have_css("button", text: /confirm/i, count: 1)
    end

    it "charges nothing on Cancel" do
      slip_line("Consult the Client").click_button("Spend")
      click_button "Cancel"

      expect(page).to have_no_button("Confirm")
      expect(page).to have_text(/8 preparation/i)
    end

    it "charges the half and writes the Docket when he confirms" do
      slip_line("Request documents").click_button("Spend")
      click_button "Confirm"

      expect(page).to have_text(/6 preparation/i)

      click_button "Turn the page over"
      expect(page).to have_text("Request documents")
    end

    # ADR 0006: a Consult yields no paper, so what it lands is a Docket line and
    # a Client who has been read. The words are the memo's; the line is what
    # survives the Day.
    it "lands a Consult as a Docket line and a Band, with no paper behind it" do
      slip_line("Consult the Client").click_button("Spend")
      click_button "Confirm"
      click_button "Turn the page over"

      expect(page).to have_text(/Consult the Client — Sam Ortega · the Client reads \w+/)
    end

    it "is accessible with a confirmation open" do
      slip_line("Consult the Client").click_button("Spend")

      expect(page).to be_axe_clean
    end
  end

  # The Consult, which is the one Action that buys words rather than paper — and
  # the one place in the whole game a face is drawn (ADR 0005).
  describe "consulting the Client" do
    before { visit "/demo/#{Demo::Seed::DEMO}" }

    def slip_line(label) = find("li.slip", text: label)

    def consult
      slip_line("Consult the Client").click_button("Spend")
      click_button "Confirm"
    end

    # The empty state is the tutorial: the memo says what it would hold before
    # anything has been bought, rather than being absent until it is.
    it "says what has not been asked, before he asks" do
      expect(page).to have_text("You have not asked.")
      expect(page).to have_no_css("section .portrait")
    end

    # #332's arithmetic: `ready` sits at 0.8 of the bound and one 0.25 Exhibit
    # cannot reach it, so Day 3's Client is firm. That is the honest finding
    # #314 predicted and is not to be flattered by moving an authored number.
    #
    # *Which* firm line is read off the run rather than written down here: #334
    # draws a `simulations.seed` per run and it decides which variant the node
    # opens on, so a literal would be a coin flip. What is under test is that
    # the words the engine chose reach the page.
    it "prints what the Client said, under the band they said it in" do
      consult

      said = Demo::Seed.simulation(Demo::Seed::DEMO).plaintiff_side.consults.last.beat.line

      expect(page).to have_text(/reads\s+firm/i)
      expect(page).to have_text(said.squish)
    end

    it "draws the face, composed into the page rather than fetched" do
      consult

      expect(page).to have_css("section svg.portrait", visible: :all)
    end

    # Two variants are authored per band for this, and `CaseClientBand#line`
    # steps through them by the speak count — so two Consults reach both
    # whichever variant the seed opened on. The face is printed once:
    # `Portraits::Compose` keys its screen ids to the seed, the expression and
    # the size, so a second copy would be duplicate ids on one page.
    it "stacks a second asking under the first, and still draws one face" do
      consult
      consult

      expect(page).to have_css("section svg.portrait", count: 1, visible: :all)
      expect(page).to have_text("I have thought about it and the answer is still no")
      expect(page).to have_text("I have been reasonable for eleven years")
    end

    # #363 put focus back on the control because a refusal is wired to it. The
    # Consult is the first act whose whole product is words further up the page,
    # so focus follows the result instead.
    it "leaves a keyboard reader on the words he just bought" do
      consult

      expect(page).to have_text(/reads\s+firm/i)
      expect(page.evaluate_script("document.activeElement.id")).to eq("memo")
    end

    it "is accessible with the memo on the page" do
      consult

      expect(page).to be_axe_clean
    end
  end

  # Eight points of preparation, spent. Every Action on the menu is then priced
  # and refused, which is the Board's own claim about itself — and the one state
  # in the demo where a student meets a refusal rather than a price.
  describe "a half with nothing left in it" do
    before do
      simulation = Demo::Seed.simulation(Demo::Seed::DEMO)
      side = simulation.plaintiff_side
      day = simulation.days.find_by!(ordinal: Demo::Seed::DEMO_DAY)
      [CaseAction::RETAIN_EXPERT, CaseAction::DEPOSE_WITNESS].each do |kind|
        Days::Command.apply(act: :spend, side: side, day: day, by: side.members.sole, kind: kind)
      end

      visit "/demo/#{Demo::Seed::DEMO}"
    end

    # Present and dead rather than absent, and reachable rather than `disabled`:
    # the sentence saying why is the thing the Board exists to teach, so it
    # cannot be the part a keyboard skips over.
    it "keeps every control on the slip, refused and reachable" do
      expect(page).to have_text("Today's half will not cover it.", count: 6)

      control = find("#spend-consult_client")
      expect(control["aria-disabled"]).to eq("true")
      expect(control["aria-describedby"]).to eq("refusal-consult_client")
    end

    it "opens nothing when a refused control is pressed" do
      find("#spend-consult_client").click

      expect(page).to have_no_button("Confirm")
    end

    it "is accessible" do
      expect(page).to be_axe_clean
    end
  end

  # #332 hands him Day 3 untouched, so the demo never opens on a draft of his
  # own. Staging one through the real seam is how the page's other half gets
  # looked at — the mark that says our column is a draft rather than a position
  # already taken, over a block with his own name on the first line.
  #
  # The executed half has no counterpart here: committing implies the Day
  # commit, the defendant has already committed Day 3, so the Day closes and
  # the route moves to Day 4. It is covered against the read instead.
  describe "a draft he has drawn" do
    before do
      simulation = Demo::Seed.simulation(Demo::Seed::DEMO)
      side = simulation.plaintiff_side
      Offers::Stage.call(
        side: side,
        day: simulation.days.find_by!(ordinal: Demo::Seed::DEMO_DAY),
        by: side.members.sole,
        terms: {"money" => 180_000_00, "apology" => nil}
      )

      visit "/demo/#{Demo::Seed::DEMO}"
    end

    it "marks the sheet a draft, and puts his position in our column" do
      expect(page).to have_text(/draft — not executed/i)
      expect(page).to have_text("$180,000")
    end

    # He drew it, so he cannot second it, and there is nobody else to. The
    # control is present and dead, which is how the Docket teaches the Second.
    it "signs the first line and leaves the second one open to nobody" do
      expect(page).to have_text("Sam Ortega")
      expect(page).to have_button("Execute this draft", disabled: true)
    end

    it "is accessible" do
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
