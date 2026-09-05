# frozen_string_literal: true

require "rails_helper"

# An Exhibit rides a committing Offer. It moves the opposing Client only where
# the Offer touches the Terms it bears on, its shift is clipped to whatever
# travel that Client has left, and the document reaches the other Side at the
# instant the Offer commits — flagged as served and carrying no Exhibit property
# at all.
RSpec.describe "playing an Exhibit" do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:opponent) { simulation.defendant_side }
  let(:organization) { simulation.section.organization }
  let(:opening) { simulation.days.first }
  # Documents requested on Day 1 land here, so this is the first Day a Team can
  # play one. It is a flat Day: eight points of preparation and two of exchange.
  let(:day) { simulation.days.second }
  let(:dana) { a_user(organization: organization, name: "Dana", email: "dana@wiu.edu") }
  let(:ravi) { a_user(organization: organization, name: "Ravi", email: "ravi@wiu.edu") }

  # There is no roster yet, so a teammate joins the Team by acting for it.
  def a_teammate(on: day)
    Days::Command.apply(
      act: :spend, side: side, day: on, by: ravi, kind: CaseAction::CONSULT_CLIENT
    )
    ravi
  end

  # The personnel file points at the defendant Client, so the plaintiff holds it
  # to play. It bears on money and apology.
  def the_personnel_file
    @the_personnel_file ||= begin
      Days::Command.apply(
        act: :spend, side: side, day: opening, by: dana, kind: CaseAction::REQUEST_DOCUMENTS
      )
      Days::Open.call(day)
      filed_by(side, "The claimant's personnel file")
    end
  end

  def filed_by(holder, title)
    holder.case_file_documents.reload.find { |filed| filed.title == title } ||
      raise("the #{holder.role} Case File holds no #{title.inspect}")
  end

  def stage(terms:, exhibits:, on: day)
    Offers::Stage.call(side: side, day: on, by: dana, terms: terms, exhibits: exhibits)
  end

  def quote(seconded_by:, on: day)
    Days::Command.quote(
      act: :commit_offer, side: side, day: on, by: dana, seconded_by: seconded_by
    )
  end

  def commit(seconded_by:, on: day)
    Days::Command.apply(
      act: :commit_offer, side: side, day: on, by: dana, seconded_by: seconded_by
    )
  end

  # A relevant play: the Offer names money, and the personnel file bears on it.
  def play_the_personnel_file(terms: {"money" => 45_000_00})
    filed = the_personnel_file
    teammate = a_teammate
    stage(terms: terms, exhibits: [filed])
    commit(seconded_by: teammate)
  end

  describe "the quote a student confirms" do
    it "names the Offer and every Exhibit riding it as one price" do
      filed = the_personnel_file
      teammate = a_teammate
      stage(terms: {"money" => 45_000_00}, exhibits: [filed])

      confirmation = quote(seconded_by: teammate)

      expect(confirmation).to be_affordable
      expect(confirmation.cost).to eq(2)
      expect(confirmation.half).to eq(DayBudget::EXCHANGE)
      expect(confirmation.remaining_after).to eq(0)
    end

    it "charges the Offer alone where nothing rides it" do
      the_personnel_file
      teammate = a_teammate
      stage(terms: {"money" => 45_000_00}, exhibits: [])

      expect(quote(seconded_by: teammate).cost).to eq(1)
    end
  end

  describe "a half that cannot cover the Offer and every Exhibit named" do
    before do
      filed = the_personnel_file
      a_teammate
      # Nothing but the play draws on this half, so the point that leaves the
      # Side unable to afford both is written straight into the ledger.
      side.docket_entries.create!(
        day: day, lands_on_day: day, spent_by: ravi,
        case_action: nil, cost: 1, half: DayBudget::EXCHANGE
      )
      stage(terms: {"money" => 45_000_00}, exhibits: [filed])
    end

    # A partial ride would silently drop an Exhibit the Team meant to play,
    # which is the worst available failure on an irreversible act.
    it "refuses entirely, charging nothing and playing nothing" do
      expect(quote(seconded_by: ravi).refusal).to eq(:the_budget_cannot_cover_it)
      expect { commit(seconded_by: ravi) }.to raise_error(Days::Command::Refused)

      expect(CommittedOffer.count).to eq(0)
      expect(PlayedExhibit.count).to eq(0)
      expect(ClientShift.count).to eq(0)
      expect(side.budget_on(day).reload.remaining_in(DayBudget::EXCHANGE)).to eq(1)
    end

    it "leaves the Exhibit in the Team's hand for a Day it can afford" do
      expect { commit(seconded_by: ravi) }.to raise_error(Days::Command::Refused)

      expect(the_personnel_file.reload).to be_playable
      expect(opponent.case_file_documents.reload).to be_empty
    end
  end

  describe "relevance" do
    # It moves the Client only where the Offer touches the Terms it bears on.
    it "moves the opposing Client where the Offer touches a Term it bears on" do
      committed = play_the_personnel_file

      shift = ClientShift.sole
      expect(shift.side).to eq(opponent)
      expect(shift.source_kind).to eq(ClientShift::EXHIBIT_PLAYED)
      # Both player-caused kinds key to the receiving Side's own Case File row,
      # so one document is one key — ADR 0003.
      expect(shift.source_ref).to eq(filed_by(opponent, "The claimant's personnel file").id)
      expect(committed.played_exhibits.count).to eq(1)
      expect(shift.requested_fraction).to eq(0.20)
      expect(opponent.bound_consumed).to eq(0.20)
    end

    # A document arguing for reinstatement is worth nothing attached to a
    # cash-only Offer — and the personnel file is worth nothing attached to one
    # naming neither money nor an apology.
    it "writes no shift row at all for an Exhibit the Offer does not touch" do
      committed = play_the_personnel_file(terms: {"nda" => nil})

      expect(ClientShift.count).to eq(0)
      expect(opponent.bound_consumed).to be_zero
      expect(committed.played_exhibits.count).to eq(1)
    end

    it "spends and serves an irrelevant Exhibit exactly as a relevant one" do
      play_the_personnel_file(terms: {"nda" => nil})

      expect(the_personnel_file.reload).to be_played
      expect(filed_by(opponent, "The claimant's personnel file")).to be_served
      expect(side.budget_on(day).reload.remaining_in(DayBudget::EXCHANGE)).to be_zero
    end
  end

  describe "clipping" do
    # Shifts stack additively against one authored bound, and the bound
    # saturates rather than refusing: a Team cannot see the bound it would be
    # punished for missing.
    def exhaust_the_defendant_bound(by:)
      ClientShift.create!(
        side: opponent, day: opening,
        source_kind: ClientShift::UNFAVORABLE_DISCOVERY,
        source_ref: 1, requested_fraction: by
      )
    end

    it "clips the shift to the travel that remains and still lands it" do
      exhaust_the_defendant_bound(by: 0.9)

      play_the_personnel_file

      shift = ClientShift.find_by!(source_kind: ClientShift::EXHIBIT_PLAYED)
      expect(shift.requested_fraction).to eq(0.20)
      expect(shift.applied_fraction).to eq(0.10)
      expect(opponent.bound_consumed).to eq(1)
    end

    # It scores regardless: a good argument put to a Client who has already come
    # around is still a good argument.
    it "spends and serves an Exhibit played into an exhausted bound" do
      exhaust_the_defendant_bound(by: 1)

      play_the_personnel_file

      shift = ClientShift.find_by!(source_kind: ClientShift::EXHIBIT_PLAYED)
      expect(shift.applied_fraction).to be_zero
      expect(the_personnel_file.reload).to be_played
      expect(filed_by(opponent, "The claimant's personnel file")).to be_served
    end
  end

  describe "service" do
    before { play_the_personnel_file }

    # Service gives a Team knowledge, never ammunition.
    it "puts the document in the opposing Case File flagged as served" do
      served = filed_by(opponent, "The claimant's personnel file")

      expect(served).to be_served
      expect(served.day).to eq(day)
    end

    it "strips the Exhibit property off the served copy" do
      served = filed_by(opponent, "The claimant's personnel file")

      expect(served).not_to be_exhibit
      expect(served.exhibit_shift_fraction).to be_nil
      expect(served).not_to be_playable
      expect(served).not_to be_unfavorable
    end

    # The Exhibit is spent when played; the document is not.
    it "leaves the played document in the playing Team's own Case File" do
      held = the_personnel_file.reload

      expect(side.case_file_documents.reload).to include(held)
      expect(held).not_to be_served
      expect(held).to be_played
      expect(held).not_to be_playable
    end
  end

  describe "an Exhibit plays exactly once" do
    before { play_the_personnel_file }

    # The seam's refusal is the rule a student reads: a Boardroom reads
    # playability off the Case File and never offers a spent Exhibit.
    it "is not a card a later Day can attach again" do
      following = simulation.days.third
      Days::Open.call(following)

      expect {
        stage(terms: {"money" => 40_000_00}, exhibits: [the_personnel_file.reload], on: following)
      }.to raise_error(ArgumentError, /is not an Exhibit this Team holds to play/)
    end

    # This is the rule underneath it, which an insert path added later cannot
    # get round.
    it "is a unique index rather than a check the seam remembers" do
      played = PlayedExhibit.sole

      expect {
        PlayedExhibit.create!(
          side: side, day: day, committed_offer: played.committed_offer,
          case_file_document: the_personnel_file
        )
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  # Any number may ride one Offer. What stops a Team dumping its hoard is the
  # exchange half, which does not carry to the next Day — so past the knee,
  # where that half widens to three, two Exhibits fit behind one Offer and a
  # third does not.
  describe "more than one Exhibit riding one Offer" do
    # A second document behind an Action the plaintiff can buy, pointing at the
    # defendant Client and bearing on a Term the reference Case's own Exhibits
    # do not. Authored here rather than in `db/cases/reference.yml`, which
    # authors one playable Exhibit per Side.
    def a_second_exhibit
      version = simulation.case_version
      document = version.documents.create!(
        case_action: version.actions.find_by!(kind: CaseAction::RESEARCH_PRECEDENT),
        identifier: "expert_report_on_reinstatement",
        title: "Expert report on reinstatement",
        body: "Authored prose for the expert report.",
        exhibit_target_role: Side::DEFENDANT,
        exhibit_shift_fraction: 0.30
      )
      document.document_terms.create!(case_term: version.terms.find_by!(key: "reinstatement"))
      document
    end

    # Past the knee at three fifths of a ten-Day Simulation, so the exchange
    # half is three: one Offer and two Exhibits, exactly.
    let(:closing) { simulation.days.find_by!(ordinal: 7) }

    def hold_both_exhibits
      a_second_exhibit
      Days::Command.apply(
        act: :spend, side: side, day: opening, by: dana, kind: CaseAction::REQUEST_DOCUMENTS
      )
      Days::Command.apply(
        act: :spend, side: side, day: opening, by: dana, kind: CaseAction::RESEARCH_PRECEDENT
      )
      Days::Open.call(day)
      Days::Open.call(closing)
      [
        filed_by(side, "The claimant's personnel file"),
        filed_by(side, "Expert report on reinstatement")
      ]
    end

    it "charges a point for each and moves the Client by both" do
      riding = hold_both_exhibits
      teammate = a_teammate(on: closing)
      stage(terms: {"money" => 45_000_00, "reinstatement" => nil}, exhibits: riding, on: closing)

      committed = commit(seconded_by: teammate, on: closing)

      expect(committed.played_exhibits.count).to eq(2)
      expect(side.budget_on(closing).reload.remaining_in(DayBudget::EXCHANGE)).to be_zero
      expect(opponent.bound_consumed).to eq(0.50)
      expect(opponent.case_file_documents.reload.map(&:title)).to contain_exactly(
        "The claimant's personnel file", "Expert report on reinstatement"
      )
    end

    it "refuses the pair the flat Day's half cannot cover" do
      riding = hold_both_exhibits
      teammate = a_teammate
      stage(terms: {"money" => 45_000_00, "reinstatement" => nil}, exhibits: riding)

      expect(quote(seconded_by: teammate).refusal).to eq(:the_budget_cannot_cover_it)
      expect(PlayedExhibit.count).to eq(0)
    end
  end

  # One document moves one Client once. The same authored document can reach a
  # Client twice — found unfavorably by their own Team, and played as an Exhibit
  # by the other — and the second arrival moves nothing, because it is the same
  # argument put a second time. The deposition is exactly that document: it
  # points at the plaintiff Client, and either Team can depose the witness.
  describe "a document that reaches one Client twice" do
    let(:kofi) { a_user(organization: organization, name: "Kofi", email: "kofi@wiu.edu") }
    # A deposition bought on Day 1 lands here.
    let(:landing) { simulation.days.third }
    let(:deposition) { "Deposition of the plant supervisor" }

    def depose(for_side, by:, on: opening)
      Days::Command.apply(
        act: :spend, side: for_side, day: on, by: by, kind: CaseAction::DEPOSE_WITNESS
      )
    end

    # The Offer names money, which the deposition bears on, so the play is a
    # relevant one and would move the plaintiff Client if anything could.
    def the_defendant_plays_it
      Days::Command.apply(
        act: :spend, side: opponent, day: landing, by: kofi, kind: CaseAction::CONSULT_CLIENT
      )
      Offers::Stage.call(
        side: opponent, day: landing, by: ravi, terms: {"money" => 30_000_00},
        exhibits: [filed_by(opponent, deposition)]
      )
      Days::Command.apply(
        act: :commit_offer, side: opponent, day: landing, by: kofi, seconded_by: kofi
      )
    end

    it "moves the Client at discovery, and not again when the other Side plays it" do
      depose(side, by: dana)
      depose(opponent, by: ravi)
      Days::Open.call(landing)
      expect(side.bound_consumed).to eq(0.25)

      committed = the_defendant_plays_it

      expect(side.bound_consumed).to eq(0.25)
      expect(ClientShift.where(side: side).count).to eq(1)
      # The Exhibit is still spent for it, and the Team is not told why not.
      expect(committed.played_exhibits.count).to eq(1)
      expect(filed_by(opponent, deposition)).to be_played
    end

    # Service is not a way to take a document back, so a Team that finds one it
    # was shown holds it as found — Exhibit property and all. The movement it
    # would have written is the one already there.
    it "moves the Client when it is served, and not again when they find it" do
      depose(opponent, by: ravi)
      Days::Open.call(landing)

      the_defendant_plays_it
      expect(side.bound_consumed).to eq(0.25)
      expect(filed_by(side, deposition)).to be_served

      depose(side, by: dana, on: landing)
      Days::Open.call(simulation.days.fifth)

      found = filed_by(side, deposition)
      expect(found).not_to be_served
      expect(found).to be_exhibit
      expect(found).to be_unfavorable
      expect(found).not_to be_playable
      expect(side.bound_consumed).to eq(0.25)
      expect(ClientShift.where(side: side).count).to eq(1)
    end
  end

  # Two Days are open at a time, so a Team can attach an Exhibit to tomorrow's
  # draft and then spend it on today's Offer before tomorrow's commits.
  describe "an Exhibit spent on another open Day" do
    it "refuses the whole play on the later Day rather than dropping the spent one" do
      filed = the_personnel_file
      teammate = a_teammate
      following = simulation.days.third
      Days::Open.call(following)
      stage(terms: {"money" => 40_000_00}, exhibits: [filed], on: following)
      stage(terms: {"money" => 45_000_00}, exhibits: [filed])

      commit(seconded_by: teammate)

      expect(quote(seconded_by: teammate, on: following).refusal)
        .to eq(:an_exhibit_has_already_been_played)
      expect { commit(seconded_by: teammate, on: following) }
        .to raise_error(Days::Command::Refused)
      expect(side.budget_on(following).reload.remaining_in(DayBudget::EXCHANGE)).to eq(2)
    end
  end

  describe "an Exhibit cannot be played alone" do
    it "has no act of its own on the command seam" do
      expect(Days::Command::ACTS).to contain_exactly(:spend, :commit_offer)
    end

    # There is no row here without an Offer to ride, and the column says so.
    it "has nowhere to be attached but a staged Offer" do
      expect {
        StagedOfferExhibit.create!(case_file_document: the_personnel_file)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  # Check, spend, play, serve — one transaction. A Team is never charged for a
  # play that half happened.
  it "leaves the Budget, the ledger and both Case Files untouched when a step fails" do
    filed = the_personnel_file
    teammate = a_teammate
    stage(terms: {"money" => 45_000_00}, exhibits: [filed])
    allow(Days::Commit).to receive(:call).and_raise("the Day commit fell over")

    expect { commit(seconded_by: teammate) }.to raise_error("the Day commit fell over")

    expect(side.budget_on(day).reload.remaining_in(DayBudget::EXCHANGE)).to eq(2)
    expect(CommittedOffer.count).to eq(0)
    expect(PlayedExhibit.count).to eq(0)
    expect(ClientShift.count).to eq(0)
    expect(opponent.case_file_documents.reload).to be_empty
    expect(filed.reload).to be_playable
  end

  # The confirmation dialog is rendered from `quote`, and staging is ungated, so
  # a teammate can add an Exhibit to the play while it is on screen. What is
  # charged is the position on the table now, because that is what lands.
  it "charges the play on the table now rather than the one quoted" do
    filed = the_personnel_file
    teammate = a_teammate
    stage(terms: {"money" => 45_000_00}, exhibits: [])
    command = Days::Command.new(
      act: :commit_offer, side: side, day: day, by: dana, seconded_by: teammate
    )
    expect(command.quote.cost).to eq(1)
    stage(terms: {"money" => 45_000_00}, exhibits: [filed])

    committed = command.apply

    expect(committed.played_exhibits.count).to eq(1)
    expect(side.budget_on(day).reload.remaining_in(DayBudget::EXCHANGE)).to be_zero
  end
end
