# frozen_string_literal: true

require "rails_helper"

# The whole of a Day as one page. What is under test is the seam rather than the
# five reads behind it: that every domain object has become something a page can
# render, that the sentences the engine names its rules by have arrived, and
# that nothing here decided anything the reads had not already decided.
RSpec.describe WorkingDraft do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:opponent) { simulation.defendant_side }
  let(:day) { simulation.days.first }
  let(:dana) { a_user(organization: simulation.section.organization) }
  let(:priya) do
    a_user(organization: simulation.section.organization, name: "Priya Raman",
      email: "priya@example.edu")
  end

  def props(on: day, you: dana) = described_class.for(side, day: on, you: you).to_props

  def track(key) = props[:term_sheet][:tracks].find { |row| row[:term] == key }

  def action(kind) = props[:slip][:actions].find { |row| row[:kind] == kind }

  # `Side#members` folds from Attribution alone, so a teammate who has done
  # nothing cannot second anything. This is what makes Priya one of us.
  def seconder_on_this_side
    Days::Command.apply(act: :spend, side: side, day: day, by: priya,
      kind: CaseAction::CONSULT_CLIENT)
  end

  describe "the letterhead" do
    it "names the matter, the Side and the Day" do
      expect(props[:letterhead]).to include(
        matter: simulation.case_version.case.name,
        role: Side::PLAINTIFF,
        day: 1,
        of: 10
      )
    end

    # Who is reading is handed in. There is no authentication, so nothing here
    # could work it out — and the roster it used to be folded from answers a
    # different question.
    it "names whoever is reading, on a Team that has done nothing" do
      expect(props[:letterhead][:you]).to eq(dana.name)
    end

    # The case that separates the two questions. Both have acted, so the roster
    # is two and could name neither of them; the letterhead names the one
    # holding the page.
    it "names the reader rather than the Team, once two members have acted" do
      Days::Command.apply(act: :spend, side: side, day: day, by: dana,
        kind: CaseAction::CONSULT_CLIENT)
      Offers::Stage.call(side: side, day: day, by: priya, terms: {"apology" => nil})

      expect(side.members).to contain_exactly(dana, priya)
      expect(props(you: priya)[:letterhead][:you]).to eq(priya.name)
    end
  end

  describe "the term sheet" do
    before do
      # Dana has to have acted on that Side before she can second anything on
      # it: `Side#members` folds from Attribution and nothing else.
      Days::Command.apply(act: :spend, side: opponent, day: day, by: dana,
        kind: CaseAction::CONSULT_CLIENT)
      Offers::Stage.call(side: opponent, day: day, by: priya,
        terms: {"money" => 40_000_00, "nda" => nil})
      Days::Command.apply(act: :commit_offer, side: opponent, day: day, by: priya,
        seconded_by: dana)
    end

    it "formats money once, here, so the page has nothing to compute" do
      expect(track("money")[:theirs]).to eq(amount: "$40,000", money: true)
    end

    it "keeps a Term addressed without a figure apart from a Term nobody named" do
      expect(track("nda")[:theirs]).to eq(amount: nil, money: false)
      expect(track("apology")[:theirs]).to be_nil
    end

    it "carries the Client's aspiration in the margin" do
      expect(track("money")[:aspiration]).to eq(amount: "$250,000", money: true)
    end

    # A Term's key is authored per Case, so the engine has no sentence for it.
    # The authored label is #343; until it lands this is what the page shows.
    it "humanizes a Term's key for want of an authored label" do
      expect(track("money")[:label]).to eq("Money")
      expect(track("reference_letter")[:label]).to eq("Reference letter")
    end
  end

  it "passes the empty states through from the reads that own them" do
    expect(props[:term_sheet][:empty_state]).to include("an offer of nothing is a position")
    expect(props[:back][:docket][:empty_state]).to include("Nothing yet")
  end

  describe "the countersignature block" do
    it "is blank before there is a draft to sign, which is how the Day teaches it" do
      expect(props[:countersignature]).to eq(
        drawn_by: nil, signed_by: nil, may_sign: [], executed: false, waived: false
      )
    end

    it "names who drew the draft and the teammates who may sign it" do
      Offers::Stage.call(side: side, day: day, by: dana, terms: {"apology" => nil})
      Days::Command.apply(act: :spend, side: side, day: day, by: priya,
        kind: CaseAction::CONSULT_CLIENT)

      expect(props[:countersignature]).to include(
        drawn_by: dana.name, may_sign: [priya.name], executed: false
      )
    end

    # A Side of one: the block is present, and the blank names nobody.
    it "names nobody on a Side whose only member drew the draft" do
      Offers::Stage.call(side: side, day: day, by: dana, terms: {"apology" => nil})

      expect(props[:countersignature]).to include(drawn_by: dana.name, may_sign: [])
    end

    # Once it is executed the block is a record, not an invitation: both lines
    # are filled and nobody may sign a thing that has already gone through.
    it "fills both lines once the Offer is committed" do
      seconder_on_this_side
      Offers::Stage.call(side: side, day: day, by: dana, terms: {"apology" => nil})
      Days::Command.apply(act: :commit_offer, side: side, day: day, by: dana,
        seconded_by: priya)

      expect(props[:countersignature]).to include(
        drawn_by: dana.name, signed_by: priya.name, may_sign: [],
        executed: true, waived: false
      )
    end

    # A commit through the Instructor's waiver has no seconder at all, so the
    # second line is not blank-and-waiting — it is waived, and says so.
    it "says the second line was waived when there is no seconder" do
      Offers::Stage.call(side: side, day: day, by: dana, terms: {"apology" => nil})
      Offers::WaiveSecond.call(side: side, day: day, by: dana)
      Days::Command.apply(act: :commit_offer, side: side, day: day, by: dana,
        seconded_by: nil)

      expect(props[:countersignature]).to include(
        drawn_by: dana.name, signed_by: nil, executed: true, waived: true
      )
    end
  end

  # The distinction grammar C is built on: a draft on the table is not a
  # position already taken, and the sheet says which it is looking at.
  describe "whether our column is a draft" do
    it "is not staged before anyone has drawn one" do
      expect(props[:term_sheet][:ours_staged]).to be(false)
    end

    it "is staged while the draft is on the table" do
      Offers::Stage.call(side: side, day: day, by: dana, terms: {"apology" => nil})

      expect(props[:term_sheet][:ours_staged]).to be(true)
    end

    it "stops being staged once it is executed" do
      seconder_on_this_side
      Offers::Stage.call(side: side, day: day, by: dana, terms: {"apology" => nil})
      Days::Command.apply(act: :commit_offer, side: side, day: day, by: dana,
        seconded_by: priya)

      expect(props[:term_sheet][:ours_staged]).to be(false)
    end
  end

  describe "the slip" do
    it "carries what each half will still buy" do
      expect(props[:slip][:remaining]).to eq(
        DayBudget::PREPARATION => {left: 8, label: "preparation"},
        DayBudget::EXCHANGE => {left: 2, label: "exchange"}
      )
    end

    it "gives every Action its sentence, its price and the Day it lands on" do
      expect(action(CaseAction::DEPOSE_WITNESS)).to include(
        label: "Depose a witness", cost: 3, half_label: "preparation",
        landing_day: 3, lands_today: false, affordable: true, refusal: nil
      )
    end

    # A refusal is a symbol the engine names a rule by; the page needs the
    # sentence, and it comes from the one file that holds machine copy.
    it "renders a refusal as its sentence, with the Action still priced" do
      Days::Command.apply(act: :spend, side: side, day: day, by: dana,
        kind: CaseAction::RETAIN_EXPERT)

      expect(action(CaseAction::RETAIN_EXPERT)).to include(
        cost: 5, affordable: false, refusal: "Today's half will not cover it."
      )
    end

    # What a confirmation is written from: a price is a trade-off only against
    # what is left once it is paid.
    it "says what the half would still hold if each Action went through" do
      expect(action(CaseAction::DEPOSE_WITNESS)).to include(remaining_after: 5)
      expect(action(CaseAction::RETAIN_EXPERT)).to include(remaining_after: 3)
    end

    it "carries no remaining-after on an Action it has already refused" do
      Days::Command.apply(act: :spend, side: side, day: day, by: dana,
        kind: CaseAction::RETAIN_EXPERT)

      expect(action(CaseAction::RETAIN_EXPERT)).to include(remaining_after: nil)
    end

    # The one mark that separates an Action he cannot afford from an Action he
    # tried to buy a moment ago. Nothing anywhere remembers a refusal, so it is
    # handed in and survives exactly this read.
    describe "a spend that was just refused" do
      def refused_props(kind:, reason:)
        described_class.for(side, day: day, you: dana,
          refused: {"kind" => kind, "reason" => reason}).to_props
      end

      it "stamps the line it was refused on, and only that one" do
        props = refused_props(kind: CaseAction::RETAIN_EXPERT,
          reason: "the_budget_cannot_cover_it")
        stamped = props[:slip][:actions].select { |row| row[:refused_just_now] }

        expect(stamped.pluck(:kind)).to eq([CaseAction::RETAIN_EXPERT])
      end

      # The fallback the seam documents as impossible: a half back under its
      # ceiling between the failed charge and this read. The line would carry a
      # stamp with nothing under it, so the carried reason is what it reads.
      it "gives the stamped line the carried sentence where the quote has none" do
        props = refused_props(kind: CaseAction::RETAIN_EXPERT,
          reason: "the_budget_cannot_cover_it")
        line = props[:slip][:actions].find { |row| row[:kind] == CaseAction::RETAIN_EXPERT }

        expect(line).to include(affordable: true, refusal: "Today's half will not cover it.")
      end

      it "marks nothing when no spend was refused" do
        expect(props[:slip][:actions]).to all(include(refused_just_now: false, refusal: nil))
      end
    end
  end

  # The Consult is the one Action that buys words rather than paper, so the memo
  # is the only place they land — and the only place a face is drawn.
  describe "the Client's memo" do
    def consult(by: dana)
      Days::Command.apply(act: :spend, side: side, day: day, by: by,
        kind: CaseAction::CONSULT_CLIENT)
    end

    it "says what a Team that has not asked is missing, and draws nobody" do
      expect(props[:memo][:entries]).to be_empty
      expect(props[:memo][:portrait]).to be_nil
      expect(props[:memo][:empty_state]).to include("You have not asked")
    end

    it "carries what the Client said, under the band they said it in" do
      consult

      expect(props[:memo][:entries].sole).to include(band: "firm")
      expect(props[:memo][:entries].sole[:line]).to be_present
    end

    # Two variants are authored per band for exactly this, so the second Consult
    # is a second thing heard rather than the first one repeated.
    it "stacks a Day's Consults newest first" do
      consult
      consult

      # The association orders by id, so these are in the order they were bought.
      first, second = side.docket_entries.consults.to_a
      lines = props[:memo][:entries].pluck(:line)

      expect(lines).to eq([ConsultMemo.for(second).beat.line, ConsultMemo.for(first).beat.line])
      expect(lines.uniq.length).to eq(2)
    end

    # The face is the one portrait in the game, and `Portraits::Compose` keys
    # its screen ids to the seed, the expression and the size — so a second copy
    # on one page would be the same ids twice, which is invalid HTML before it
    # is anything else.
    it "prints one face however many times the Client was asked" do
      consult
      consult

      expect(props[:memo][:portrait]).to include("<svg")
      expect(props[:memo][:portrait].scan("<svg").length).to eq(1)
    end

    # ADR 0008 binds the read: `ConsultMemo::Beat` hands on a seed and an
    # expression and never a picture. The size exists here and nowhere earlier.
    it "composes the face at the one size the memo serves" do
      consult

      expect(props[:memo][:portrait]).to include(%(width="#{WorkingDraft::PORTRAIT_SIZE}"))
      expect(Portraits::Compose::SIZES).to include(WorkingDraft::PORTRAIT_SIZE)
    end

    # The front of the instrument is today's working state. What survives a Day
    # is the band on the Docket line; the wording is bought for the Day it was
    # bought on.
    it "carries this Day's Consults and not another Day's" do
      consult
      other = simulation.days.find_by!(ordinal: 2)

      expect(props(on: other)[:memo][:entries]).to be_empty
      expect(props(on: other)[:memo][:empty_state]).to be_present
    end

    # One key, both surfaces: a band spelled one way on the memo and another on
    # the Docket line would be two vocabularies for one rule.
    it "spells the band the same way the Docket line does" do
      consult

      expect(props[:back][:docket][:entries].sole[:band])
        .to eq(props[:memo][:entries].sole[:band])
    end
  end

  describe "the back of the file" do
    it "names a spend by the Action it bought and the member who spent it" do
      Days::Command.apply(act: :spend, side: side, day: day, by: dana,
        kind: CaseAction::REQUEST_DOCUMENTS)

      expect(props[:back][:docket][:entries].sole).to include(
        act_label: "Request documents", by: dana.name, day: 1, cost: 2,
        half_label: "preparation", lands_on_day: 2, spend: true
      )
    end

    # The three acts with no cost have no Action behind them to name, so the act
    # names itself — and the nil cost is left visible rather than shown as zero.
    it "names an act with no cost by the act" do
      Offers::Stage.call(side: side, day: day, by: dana, terms: {"apology" => nil})

      expect(props[:back][:docket][:entries].sole).to include(
        act_label: "Drew a draft", by: dana.name, cost: nil, spend: false
      )
    end

    it "reduces a document to what a page can render" do
      expect(props[:back][:case_file][:documents].first).to include(
        day: 1, served: false, at_the_open: true
      )
    end
  end

  # The claim the composer exists to make: no `Day`, no `User` and no symbol the
  # engine names a rule by survives into the props. A leaf that is not a JSON
  # scalar is an object the page would have to know how to render.
  it "hands the page nothing but JSON scalars" do
    Days::Command.apply(act: :spend, side: side, day: day, by: dana,
      kind: CaseAction::CONSULT_CLIENT)

    leaves = []
    walk = lambda do |node|
      case node
      when Hash then node.each_value { |value| walk.call(value) }
      when Array then node.each { |value| walk.call(value) }
      else leaves << node
      end
    end
    walk.call(props)

    expect(leaves).to all(be_a(String).or(be_a(Integer)).or(be_a(Float))
      .or(be(true)).or(be(false)).or(be_nil))
  end

  it "writes nothing" do
    expect { props }.not_to change(DocketEntry, :count)
    expect { props }.not_to change(StagedOffer, :count)
  end
end
