# frozen_string_literal: true

require "rails_helper"

# Drawing the position. What is under test is the seam between the address and
# `Offers::Stage`: which Side's table it lands on, who it is attributed to, what
# the Case's vocabulary and the Case File's identifiers are allowed to name, and
# what comes back when the Day has ended underneath it.
#
# Unlike a spend there is no price and no Docket row — staging costs nothing and
# writes none — so what is asserted is the position itself.
RSpec.describe "drawing the Offer", type: :request do
  before { Demo::Seed.call }

  let(:simulation) { Demo::Seed.simulation(Demo::Seed::DEMO) }
  let(:side) { simulation.plaintiff_side }
  let(:day) { simulation.days.find_by!(ordinal: Demo::Seed::DEMO_DAY) }
  let(:player) { User.find_by!(email: Demo::Seed::PLAYER_EMAIL) }

  def draw(terms: ["money"], amount: "$150,000", exhibits: [], note: nil,
    run: Demo::Seed::DEMO, seat: nil, on: Demo::Seed::DEMO_DAY)
    post ["/demo/#{run}", seat, "offers"].compact.join("/"),
      params: {terms: terms, amount: amount, exhibits: exhibits, note: note, day: on}
  end

  def staged = side.staged_offer_on(day)

  describe "a position he has written" do
    it "puts it on his own table and sends him back to read it" do
      expect { draw }.to change { side.staged_offers.count }.by(1)

      expect(response).to redirect_to("/demo/#{Demo::Seed::DEMO}")
    end

    # The map's standing constraint: `Side#members` folds from Attribution, so a
    # position attributed to anyone else would put a second member on this Side
    # and make the countersignature block live.
    it "attributes it to the seat that drew it" do
      draw

      expect(staged.staged_by.email).to eq(Demo::Seed::PLAYER_EMAIL)
      expect(side.members.map(&:email)).to eq([Demo::Seed::PLAYER_EMAIL])
    end

    # Dollars in, cents on the row. The symbol and the separators a student
    # writes are stripped at the boundary, because the field they are typed into
    # opens holding the *printed* figure — see `WorkingDraft#drafted`.
    it "converts the figure it was written in to the cents the row holds" do
      draw(amount: "$150,000")

      expect(staged.amount_cents).to eq(150_000_00)
    end

    it "reads a figure written plainly, and one written to the penny" do
      draw(amount: "45000")
      expect(staged.amount_cents).to eq(45_000_00)

      draw(amount: "45000.50")
      expect(staged.amount_cents).to eq(45_000_50)
    end

    # A Term is atomic, so the six that are not money arrive named and nothing
    # else. A Term left off the sheet is absent rather than zero — an offer of
    # nothing is a position somebody took.
    it "carries the Terms without figures as themselves" do
      draw(terms: %w[money apology reinstatement])

      expect(staged.offer_terms.map { |row| [row.key, row.amount_cents] })
        .to match_array([["money", 150_000_00], ["apology", nil], ["reinstatement", nil]])
    end

    it "writes nothing at all on a Term nobody put on the table" do
      draw(terms: ["apology"], amount: nil)

      expect(staged.terms.map(&:key)).to eq(["apology"])
    end

    it "keeps the covering note he wrote under it" do
      draw(note: "Without prejudice. Open until close of business.")

      expect(staged.note).to eq("Without prejudice. Open until close of business.")
    end
  end

  # The Exhibit rides the *staged* Offer rather than being named at the commit,
  # so that the teammate who Seconds is confirming the whole play. It costs
  # nothing to clip one; what it costs is quoted on the countersignature block.
  describe "an Exhibit clipped to it" do
    let(:personnel_file) { "personnel_file" }

    it "rides the position out of this Team's own Case File" do
      draw(exhibits: [personnel_file])

      expect(staged.exhibits.map { |filed| filed.case_document.identifier })
        .to eq([personnel_file])
    end

    # A document the other Side served is knowledge and never ammunition —
    # `CaseFile` strips the Exhibit property off a served row on read, so the
    # rail never offers it. Reaching for it anyway is the caller's doing.
    it "does not know an Exhibit off a document he was served" do
      draw(exhibits: ["deposition_of_the_supervisor"])

      expect(response).to have_http_status(:not_found)
      expect(staged).to be_nil
    end

    it "does not know a document this Team does not hold" do
      draw(exhibits: ["report_of_the_employment_expert"])

      expect(response).to have_http_status(:not_found)
    end
  end

  # A revision replaces the position rather than amending it, which is one seam
  # and not two — and it replaces the Exhibits for the same reason it replaces
  # the Terms: they are one position, and a teammate Seconds the whole of it.
  describe "revising what is already on the table" do
    before { draw(terms: %w[money nda], exhibits: ["personnel_file"], note: "First pass.") }

    it "replaces the Terms rather than adding to them" do
      draw(terms: ["apology"], amount: nil)

      expect(staged.terms.map(&:key)).to eq(["apology"])
    end

    it "replaces the Exhibits riding it, and takes one off when none are named" do
      draw(terms: ["money"], exhibits: [])

      expect(staged.exhibits).to be_empty
    end

    it "leaves one live draft on the Day rather than a second" do
      expect { draw(terms: ["training"], amount: nil) }
        .not_to change { side.staged_offers.where(day: day).count }
    end

    # `staged_by` is who put the Offer on the table and does not move: the
    # Second is measured against them, so a revision that reassigned it would
    # erase the one member the gate is defined against.
    it "does not move who drew it" do
      draw(terms: ["training"], amount: nil)

      expect(staged.staged_by.email).to eq(Demo::Seed::PLAYER_EMAIL)
    end
  end

  # The second tab is a different person on the other Side, and the address is
  # the whole of what says so. Read on the cold open, where neither Side has
  # committed anything: the demo run's defendant executed its Day 3 before the
  # player sat down, and a Day whose Offer is committed has no table left to draw
  # on.
  it "draws on the table the seat sits at" do
    cold = Demo::Seed.simulation(Demo::Seed::COLD_OPEN)
    cold_day = cold.days.find_by!(ordinal: 1)

    draw(run: Demo::Seed::COLD_OPEN, seat: Side::DEFENDANT,
      terms: ["training"], amount: nil, on: 1)

    expect(cold.defendant_side.staged_offer_on(cold_day).terms.map(&:key)).to eq(["training"])
    expect(cold.plaintiff_side.staged_offers).to be_empty
    expect(response).to redirect_to("/demo/#{Demo::Seed::COLD_OPEN}/#{Side::DEFENDANT}")
  end

  # A Team commits at most one Offer a Day, so a Day whose Offer is executed has
  # no second position to put on the table. The sheet withdraws its inputs there,
  # so reaching this is a page that went stale — and the seam is what refuses it,
  # rather than the screen, because `TermsBoard#ours` prefers the draft to the
  # committed Offer: a revision landing here would leave the executed instrument
  # printing terms over two countersignatures that never signed them.
  describe "a Day whose Offer is already executed" do
    it "refuses the draft rather than revising what was executed" do
      expect {
        draw(seat: Side::DEFENDANT, terms: ["training"], amount: nil)
      }.not_to change { simulation.defendant_side.staged_offer_on(day).terms.map(&:key) }

      follow_redirect!
      expect(inertia.props[:term_sheet][:refusal])
        .to eq("Your team has already executed an offer today.")
    end

    # The whole window this closes: the Day stays open until the other Side
    # commits, so a tab left sitting on it is not looking at a closed Day.
    it "is refused on a Day that is still open" do
      draw(seat: Side::DEFENDANT, terms: ["training"], amount: nil)
      follow_redirect!

      expect(day.reload).not_to be_closed
    end
  end

  # One seat, one address, however it was reached. #360 handed the player the
  # bare form, and an act he takes should not spell his seat out from under him.
  it "keeps the player on the address he was handed" do
    draw(seat: Side::PLAINTIFF)

    expect(response).to redirect_to("/demo/#{Demo::Seed::DEMO}")
  end

  # The sheet withdraws its inputs on a Day that has ended, so this is a page
  # that went stale: the Day closed between the render and the press. It is a
  # refusal the engine already names, so it comes back as the engine's own symbol
  # and becomes a sentence on the page rather than a fault.
  describe "a Day that ended under the drafting" do
    # The defendant has already committed Day 3, so the plaintiff's commitment
    # is the second and closes it.
    before { Days::Commit.call(side: side, day: day, by: player) }

    it "refuses it without writing a position" do
      expect { draw }.not_to change(StagedOffer, :count)

      follow_redirect!
      expect(inertia.props[:term_sheet][:refusal]).to eq("This Day has closed. The next one opens on the Instructor's schedule.")
    end

    # The refusal has no row anywhere. It survives exactly one read.
    it "does not carry it into the next read of the same page" do
      draw
      follow_redirect!

      get "/demo/#{Demo::Seed::DEMO}"

      expect(inertia.props[:term_sheet][:refusal]).to be_nil
    end

    # The session is the browser and the demo is played from two tabs, so both
    # seats share it — but a refusal one seat earned is not the other's to read,
    # and not the other's to consume on its way past either.
    it "is not read by the other seat" do
      draw(seat: Side::PLAINTIFF)

      get "/demo/#{Demo::Seed::DEMO}/#{Side::DEFENDANT}"

      expect(inertia.props[:term_sheet][:refusal]).to be_nil
    end
  end

  # Each of these is a caller with a menu the engine never offered rather than a
  # refusal a student should see: the sheet renders the authored vocabulary,
  # offers only this Team's playable documents, and holds its control dead while
  # no Term is checked. So each reads as a 404, like a mistyped seat.
  describe "a position the sheet could not have produced" do
    it "does not know a Term the Case never authored" do
      draw(terms: ["a_public_flogging"], amount: nil)

      expect(response).to have_http_status(:not_found)
      expect(staged).to be_nil
    end

    it "does not take an Offer naming no Term at all" do
      draw(terms: [], amount: nil)

      expect(response).to have_http_status(:not_found)
    end

    it "does not take money without a figure" do
      draw(amount: nil)

      expect(response).to have_http_status(:not_found)
    end

    it "does not take a figure that is not one" do
      draw(amount: "about a hundred grand")

      expect(response).to have_http_status(:not_found)
    end

    # The figure is read **as written**. Stripping the separators first and
    # checking the digits after turns a malformed figure into a well-formed
    # different one — and a silently altered amount is the worst failure
    # available on an instrument whose whole subject is how much money changes
    # hands.
    it "does not read a malformed figure as a different amount" do
      draw(amount: "1,50")

      expect(response).to have_http_status(:not_found)
      expect(staged).to be_nil
    end

    it "does not take a group that is not three digits" do
      ["1,5000", "12,34,567", "1 50", "1.234"].each do |written|
        draw(amount: written)

        expect(response).to have_http_status(:not_found), "accepted #{written.inspect}"
      end
    end

    it "reads the figures a student would actually write" do
      {"$150,000" => 150_000_00, "150000" => 150_000_00,
       "1,500.25" => 1_500_25, "$12" => 12_00}.each do |written, in_cents|
        draw(amount: written)

        expect(staged.amount_cents).to eq(in_cents), "read #{written.inspect} wrong"
      end
    end

    # The sheet posts the sitting Day and no other, so a Day on the calendar
    # that nobody has reached is a hand-written request rather than a page that
    # went stale — the same reading the waiver's address gives it.
    it "does not draw on a Day that has not opened yet" do
      draw(on: Demo::Seed::DEMO_DAY + 1)

      expect(response).to have_http_status(:not_found)
      expect(side.staged_offers).to be_empty
    end
  end

  # The session is the browser and the demo is played from two tabs, so one
  # seat's refusal must not be readable by the other — and must not be erased by
  # it either, which a single shelf naming its own seat in the payload could not
  # promise.
  describe "two seats refused before either reads" do
    before do
      Days::Commit.call(side: side, day: day, by: player)
      draw(seat: Side::PLAINTIFF)
      draw(seat: Side::DEFENDANT)
    end

    it "keeps each seat's sentence for the seat that earned it" do
      get "/demo/#{Demo::Seed::DEMO}"
      expect(inertia.props[:term_sheet][:refusal]).to eq("This Day has closed. The next one opens on the Instructor's schedule.")

      get "/demo/#{Demo::Seed::DEMO}/#{Side::DEFENDANT}"
      expect(inertia.props[:term_sheet][:refusal]).to eq("This Day has closed. The next one opens on the Instructor's schedule.")
    end

    it "does not know a Day off the Simulation's calendar" do
      draw(on: 99)

      expect(response).to have_http_status(:not_found)
    end
  end

  it "has no table for the Instructor to draw on" do
    draw(seat: Demo::Seat::INSTRUCTOR)

    expect(response).to have_http_status(:not_found)
  end

  it "does not know a run it did not lay down" do
    draw(run: "whatever")

    expect(response).to have_http_status(:not_found)
  end
end
