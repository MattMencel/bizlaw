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
      expect(page).to have_no_text("You are looking at")
      expect(page).to have_button("Turn over: Case File & Docket")
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
      expect(page).to have_text("Struck through, their last committed offer")
    end

    # The register #373 settled carries whose a position is in a strike and a
    # margin rather than in column headings, so the headings are still there and
    # only the eye is spared them. Nothing on the sheet depends on seeing the
    # strike or the redline colour.
    it "says whose each figure is for a reader who cannot see the strike" do
      expect(page).to have_css("thead th", text: "Their last committed position", visible: :all)
      expect(page).to have_css("thead th", text: "Our position", visible: :all)
      expect(page).to have_css("table.terms caption", text: "Where there is nothing")
    end

    # The block is on the page before there is a draft to sign, because an empty
    # signature block is how the Day teaches that a commit needs a second hand.
    #
    # `aria-disabled` and not `disabled`: the control stays in the tab order so
    # the sentence saying why it cannot be pressed stays reachable with it, which
    # is the rule #363 set for an Action the half will not cover.
    it "shows the countersignature block, with the execute control dead" do
      expect(page).to have_text(/countersigned by/i)
      expect(page).to have_css("button#execute-the-draft[aria-disabled='true']")
      expect(page).to have_text("There is no draft to execute")
    end

    it "prices every Action on the slip, whether or not today will cover it" do
      expect(page).to have_text("Consult the Client")
      expect(page).to have_text("Retain an expert")
      expect(page).to have_text(/8 preparation/i)
    end

    # The cost #315 accepted for this grammar: the record surfaces live behind a
    # gesture. That the gesture reaches them is the least this can prove.
    it "turns over to the Case File and the Docket" do
      click_button "Turn over: Case File & Docket"

      expect(page).to have_button("Turn back: the draft")

      expect(page).to have_text(/back of the file/i)
      expect(page).to have_no_text(/what we know, and what we have done/i)
      expect(page).to have_text("The claimant's personnel file")
      expect(page).to have_text("Request documents")
    end

    it "is accessible" do
      expect(page).to be_axe_clean
    end

    it "is accessible on the back of the file too" do
      click_button "Turn over: Case File & Docket"

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

      click_button "Turn over: Case File & Docket"
      expect(page).to have_text("Request documents")
    end

    # ADR 0006: a Consult yields no paper, so what it lands is a Docket line and
    # a Client who has been read. The words are the memo's; the line is what
    # survives the Day.
    it "lands a Consult as a Docket line and a Band, with no paper behind it" do
      slip_line("Consult the Client").click_button("Spend")
      click_button "Confirm"
      click_button "Turn over: Case File & Docket"

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
      expect(page).to have_field(type: "text", with: "$180,000")
    end

    # He drew it, so he cannot second it, and there is nobody else to. The
    # control is present and dead, which is how the Docket teaches the Second.
    it "signs the first line and leaves the second one open to nobody" do
      expect(page).to have_text("Sam Ortega")
      expect(page).to have_css("button#execute-the-draft[aria-disabled='true']")
      expect(page).to have_text("A teammate has to countersign the draft")
    end

    # The price and the refusal together are the beat. An Offer costs one point
    # of the exchange half and this Case prices an Exhibit at one more, so a
    # draft with nothing clipped to it is one.
    it "prices executing it beside the reason he cannot" do
      expect(page).to have_text("1 exchange")
    end

    it "is accessible" do
      expect(page).to be_axe_clean
    end
  end

  # Day 1, nothing spent: the only Day on which the empty states are the whole
  # of what a student reads, and the claim that they are the tutorial.
  describe "the cold open" do
    before { visit "/demo/#{Demo::Seed::COLD_OPEN}" }

    # Every empty state names its section and says what would fill it. The two
    # in the front matter said only that there was nothing, until #368 — and
    # they are the first two things a Day 1 reader meets.
    it "is not a blank page" do
      expect(page).to have_text("An Action you spend comes back on the Day its lead time names")
      expect(page).to have_text("any exhibit riding it is served on you")
      expect(page).to have_text("an offer of nothing is a position somebody took")
      expect(page).to have_text("The termination letter")
    end

    it "still prices the whole Action Board" do
      expect(page).to have_text("Retain an expert")
      expect(page).to have_text(/5 preparation/i)
    end

    it "says what a Docket would hold" do
      click_button "Turn over: Case File & Docket"

      expect(page).to have_text("Nothing yet.")
    end

    # The claim under test is not that the sentences are written but that they
    # are the tutorial — so the Day has to be playable from them alone. One
    # press against an empty Docket turns three of them into content: the slip
    # charges, the memo fills with what the Client actually said, and the Docket
    # takes its first line. It is the cheapest Action on the board and the only
    # one that lands the same morning, which is why it is the one a cold open
    # can prove anything with.
    it "plays from the empty states alone" do
      expect(page).to have_text(/8 preparation/i)

      click_button "Spend Consult the Client"
      click_button "Confirm spending Consult the Client"

      expect(page).to have_text(/7 preparation/i)
      expect(page).to have_text(/reads firm/i)
      expect(page).to have_no_text("You have not asked.")

      click_button "Turn over: Case File & Docket"

      expect(page).to have_text("Consult the Client")
      expect(page).to have_no_text("Nothing yet. Every Action your Team spends on lands here")
    end

    it "is accessible" do
      expect(page).to be_axe_clean
    end
  end

  # The redline only has two sides to it once this Side has taken a position,
  # and #332 hands the player a Day he has not acted on — so on the seeded sheet
  # every one of our slots is blank and half the register never renders. Staging
  # a draft is what puts all four states on one sheet: a figure written over a
  # struck figure, a Term tabled without one, a Term nobody has raised, and a
  # Client who is indifferent about it.
  describe "the term sheet once there is a draft on our own table" do
    before do
      simulation = Demo::Seed.simulation(Demo::Seed::DEMO)
      Offers::Stage.call(
        side: simulation.plaintiff_side,
        day: simulation.days.find_by!(ordinal: Demo::Seed::DEMO_DAY),
        by: User.find_by!(email: Demo::Seed::PLAYER_EMAIL),
        terms: {"money" => 150_000_00, "apology" => nil}
      )
      visit "/demo/#{Demo::Seed::DEMO}"
    end

    def line_for(label) = find("th[scope='row']", text: label, exact_text: true).ancestor("tr")

    # The figure is in a field he can type over, and it is still the printed
    # figure: one currency decision, so the two halves of one ruled line are not
    # typeset as two documents.
    it "writes our figure in over theirs, struck in place" do
      expect(line_for("Money")).to have_css("s", text: "$40,000")
      expect(line_for("Money")).to have_field(type: "text", with: "$150,000")
    end

    # A Term tabled without a figure is a word on the line; a Term nobody has
    # raised is a line with nothing on it; a Client with nothing to say about it
    # leaves the margin empty. Three silences, and no word doing the work —
    # which is why Training's whole line reads as its own label and nothing
    # else, in the DOM as well as on the page.
    it "keeps the three silences apart" do
      expect(line_for("Apology")).to have_text("Included")
      expect(line_for("Training").text(:all).strip).to eq("Training")
    end

    it "is accessible" do
      expect(page).to be_axe_clean
    end
  end

  # The beat this ticket exists for: he writes a position onto the sheet, clips
  # his one Exhibit to it, and finds he cannot execute it alone.
  describe "drawing a position on the sheet" do
    before { visit "/demo/#{Demo::Seed::DEMO}" }

    def line_for(label) = find("th[scope='row']", text: label, exact_text: true).ancestor("tr")

    def write(money:, terms: [], clip: nil)
      check "Money"
      fill_in "Our position on Money, in dollars", with: money
      terms.each { |term| check term }
      check clip if clip
    end

    # Edits are local until the act, and the sheet says so — because a teammate
    # may be reading it to decide whether to countersign, and *what you are
    # looking at is not what is on the table* is the one thing the register must
    # not leave to an input's internal state.
    it "marks the sheet unposted while the edits are only his" do
      write(money: "$120,000")

      expect(page).to have_text(/not yet on the table/i)
      expect(page).to have_text(/still reading the last one/i)
    end

    it "puts the position on the table and marks it a draft" do
      write(money: "$120,000", terms: ["Apology"])
      click_button "Put this on the table"

      expect(page).to have_text(/draft — not executed/i)
      expect(page).not_to have_text(/not yet on the table/i)
      expect(line_for("Apology")).to have_text("Included")
      expect(line_for("Money")).to have_field(type: "text", with: "$120,000")
    end

    # The act's result is the sheet: what he wrote is now what the sheet prints,
    # and the mark above it has changed. #364's rule is where the result is
    # legible rather than the control that was pressed.
    it "returns him to the sheet, which is where the result reads" do
      write(money: "$120,000")
      click_button "Put this on the table"

      expect(page).to have_text(/draft — not executed/i)
      expect(page.evaluate_script("document.activeElement.id")).to eq("term-sheet")
    end

    # An Offer names at least one Term and money is worth an amount. Both are
    # caller faults at the seam rather than refusals a student should read, so
    # the control is what makes them unreachable — and it says which, staying in
    # the tab order to do it.
    it "holds the control dead with its reason while there is no position" do
      expect(page).to have_css("button#draw-the-position[aria-disabled='true']")
      expect(page).to have_text("An offer names at least one term.")
    end

    it "holds it dead while money is on the table without a figure" do
      check "Money"

      expect(page).to have_css("button#draw-the-position[aria-disabled='true']")
      expect(page).to have_text("An offer of money is worth an amount.")
    end

    # `params[:note].presence` turns a note of nothing but spaces into no note at
    # all, so a client comparing what was typed would see a difference the server
    # had already discarded — and the sheet would go on saying *Not yet on the
    # table* about a position that is on it. The mark exists to be true about
    # that one thing.
    it "clears the unposted mark when the note it sent was only spaces" do
      write(money: "$120,000")
      click_button "Put this on the table"
      expect(page).to have_text(/draft — not executed/i)

      fill_in "Covering note", with: "   "

      expect(page).to have_no_text(/not yet on the table/i)
    end

    it "is accessible while it is being written on" do
      write(money: "$120,000", terms: ["Apology"])

      expect(page).to be_axe_clean
    end
  end

  # An Exhibit rides the draft rather than being played alone, and it is clipped
  # down the side of the instrument rather than taken on the back — the back
  # being the surface #315 knowingly accepted may never be turned to.
  describe "the clip rail" do
    before { visit "/demo/#{Demo::Seed::DEMO}" }

    it "offers this Team's own playable Exhibit and nothing it was served" do
      within("aside", text: /clipped to this draft/i) do
        expect(page).to have_field("The claimant's personnel file")
        expect(page).not_to have_text("Deposition of the plant supervisor")
      end
    end

    # One point for the Offer and one more for the Exhibit is the whole of this
    # Team's exchange half, which is what makes clipping it a decision.
    it "prices the Exhibit into executing the draft as one figure" do
      check "Money"
      fill_in "Our position on Money, in dollars", with: "$120,000"
      click_button "Put this on the table"
      expect(page).to have_text("1 exchange")

      check "The claimant's personnel file"
      click_button "Put this on the table"

      expect(page).to have_text("2 exchange")
    end
  end

  # A Team that has committed today has no second Offer to draw, and an executed
  # instrument is a record rather than a working surface. The defendant's seat is
  # the live case: it drew, seconded and committed its Day 3 before the player
  # sat down.
  describe "a sheet that may not be written on" do
    before { visit "/demo/#{Demo::Seed::DEMO}/#{Side::DEFENDANT}" }

    it "prints the executed position rather than offering inputs" do
      expect(page).to have_text("$40,000")
      expect(page).to have_no_field("Our position on Money, in dollars")
      expect(page).to have_no_button("Put this on the table")
    end

    # Both lines filled, nobody left to sign, and no price for an act that has
    # already happened.
    it "reads as a record, with no control and no price" do
      expect(page).to have_text("Dana Whitfield")
      expect(page).to have_text("Ray Okonkwo")
      expect(page).to have_no_css("button#execute-the-draft")
    end

    it "is accessible" do
      expect(page).to be_axe_clean
    end
  end

  # The beat the whole demo was convened for: he draws a position, finds the
  # countersignature line dead in his own hand, and it comes alive under an
  # Instructor's waiver granted from another tab.
  #
  # The two tabs are two visits here rather than two windows. What crosses
  # between them is a database row and the page's own re-read, neither of which
  # cares how many browsers are open.
  describe "executing the draft under a waiver" do
    let(:simulation) { Demo::Seed.simulation(Demo::Seed::DEMO) }
    let(:side) { simulation.plaintiff_side }
    let(:day) { simulation.days.find_by!(ordinal: Demo::Seed::DEMO_DAY) }

    def draw_a_position
      visit "/demo/#{Demo::Seed::DEMO}"
      check "Money"
      fill_in "Our position on Money, in dollars", with: "$150,000"
      click_button "Put this on the table"
      expect(page).to have_text(/draft — not executed/i)
    end

    def waive_it
      visit "/demo/#{Demo::Seed::DEMO}/#{Demo::Seat::INSTRUCTOR}"
      find("#waive-#{Side::PLAINTIFF}").click
      expect(page).to have_text("The second is waived for this Day.")
    end

    it "brings the dead control alive, and says who released it" do
      draw_a_position

      expect(find("#execute-the-draft")["aria-disabled"]).to eq("true")

      waive_it
      visit "/demo/#{Demo::Seed::DEMO}"

      expect(find("#execute-the-draft")["aria-disabled"]).to eq("false")
      expect(page).to have_no_text("A teammate has to countersign the draft")
    end

    # Losing the refusal is not the same as being told. Without this the block
    # goes quiet — a live control over a dashed line still captioned
    # *countersigned by*, which is now a line nobody will ever sign.
    it "says the line was released rather than leaving it blank" do
      draw_a_position
      waive_it
      visit "/demo/#{Demo::Seed::DEMO}"

      # Case-insensitive: the caption is small-caps by `text-transform`, so what
      # the DOM holds and what the eye reads differ in case alone.
      expect(page).to have_text(/countersignature waived by the instructor/i)
    end

    # The same grammar the slip taught, for the same reason: this is
    # irreversible, it takes the whole exchange half, and it ends his Day. The
    # block printing a price standing is the trade-off, not an agreement to
    # spend it.
    it "confirms in place before it charges" do
      draw_a_position
      waive_it
      visit "/demo/#{Demo::Seed::DEMO}"

      find("#execute-the-draft").click

      expect(page).to have_text("1 exchange · 1 exchange left after · this also commits your Day")
      expect(page).to have_button("Confirm")
    end

    it "charges nothing on Cancel" do
      draw_a_position
      waive_it
      visit "/demo/#{Demo::Seed::DEMO}"

      find("#execute-the-draft").click
      click_button "Cancel"

      expect(page).to have_no_button("Confirm")
      expect(side.committed_offer_on(day)).to be_nil
    end

    # It lands, and the Day goes with it: a commit implies the Day commit, the
    # defendant committed Day 3 before he sat down, so Day 3 closes and Day 4
    # opens underneath him. The page moving on is the engine being honest.
    it "lands the Offer and closes the Day with it" do
      draw_a_position
      waive_it
      visit "/demo/#{Demo::Seed::DEMO}"

      find("#execute-the-draft").click
      click_button "Confirm"

      expect(page).to have_text("Day #{Demo::Seed::DEMO_DAY + 1}/10")
      expect(side.committed_offer_on(day)).to be_present
      expect(day.reload).to be_closed
    end

    # A commit that landed under a waiver carries no seconder at all, so the
    # record cannot read as though somebody signed for him.
    it "leaves a record naming the waiver rather than a countersignature" do
      draw_a_position
      waive_it
      visit "/demo/#{Demo::Seed::DEMO}"
      find("#execute-the-draft").click
      click_button "Confirm"

      click_button "Turn over: Case File & Docket"
      expect(page).to have_text(/waived.*Professor Adeyemi|Professor Adeyemi/)
      expect(side.committed_offer_on(day).seconded_by).to be_nil
    end

    it "is accessible with the execution open" do
      draw_a_position
      waive_it
      visit "/demo/#{Demo::Seed::DEMO}"
      find("#execute-the-draft").click

      expect(page).to be_axe_clean
    end
  end

  # The paper re-reads itself when you come back to it — which is what makes the
  # waiver land on a page the player never touched. There is no timer and no
  # subscription: a tab nobody is looking at learns nothing, which is what paper
  # on a desk does and the whole of what a demo on one laptop needs.
  describe "coming back to the tab" do
    it "picks up what happened in another one" do
      simulation = Demo::Seed.simulation(Demo::Seed::DEMO)
      side = simulation.plaintiff_side
      day = simulation.days.find_by!(ordinal: Demo::Seed::DEMO_DAY)
      Offers::Stage.call(side: side, day: day, by: side.members.sole,
        terms: {"apology" => nil})

      visit "/demo/#{Demo::Seed::DEMO}"
      expect(page).to have_text("A teammate has to countersign the draft")

      Offers::WaiveSecond.call(
        side: side, day: day, by: User.find_by!(email: Demo::Seed::INSTRUCTOR_EMAIL)
      )
      page.execute_script("window.dispatchEvent(new Event('focus'))")

      expect(page).to have_no_text("A teammate has to countersign the draft")
      expect(find("#execute-the-draft")["aria-disabled"]).to eq("false")
    end

    # The other half of that rule, and its limit. What is on the table is the
    # same on both sides of a Day boundary whenever neither Day has a position
    # on it — so the key alone would leave Day 3's typing sitting on Day 4's
    # sheet, under a letterhead that has moved, still marked *not yet on the
    # table* about a table that is no longer the one it was typed against. The
    # Day is part of which instrument this is, so it is part of the key.
    it "takes it away when the Day underneath it has changed" do
      simulation = Demo::Seed.simulation(Demo::Seed::DEMO)
      side = simulation.plaintiff_side
      day = simulation.days.find_by!(ordinal: Demo::Seed::DEMO_DAY)

      visit "/demo/#{Demo::Seed::DEMO}"
      check "Money"
      fill_in "Our position on Money, in dollars", with: "$99,000"

      # The Day ends under him: the defendant committed Day 3 in the seed, so a
      # teammate filing his is the second commitment and closes it.
      Days::Commit.call(side: side, day: day, by: side.members.sole)
      page.execute_script("window.dispatchEvent(new Event('focus'))")

      expect(page).to have_text("Day #{Demo::Seed::DEMO_DAY + 1}/10")
      # `disabled: :all` because the figure field is dead until Money is
      # checked, and clearing his typing unchecks it — which is the sheet
      # re-seeded from Day 4's position rather than holding Day 3's.
      expect(page).to have_field(
        "Our position on Money, in dollars", with: "", disabled: :all
      )
      expect(page).to have_no_text(/not yet on the table/i)
    end

    # It must not cost him the position he is typing. The draft is keyed on what
    # is on the *table*, so a re-read that finds the table unchanged leaves his
    # unposted edits exactly where they were.
    it "does not take away what he has not put on the table yet" do
      visit "/demo/#{Demo::Seed::DEMO}"
      check "Money"
      fill_in "Our position on Money, in dollars", with: "$99,000"
      expect(page).to have_text(/not yet on the table/i)

      page.execute_script("window.dispatchEvent(new Event('focus'))")

      expect(page).to have_field("Our position on Money, in dollars", with: "$99,000")
      expect(page).to have_text(/not yet on the table/i)
    end
  end
end
