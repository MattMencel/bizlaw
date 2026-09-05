# frozen_string_literal: true

require "rails_helper"

# A seconded Offer lands, and it costs the exchange half to do it. It enters
# through the one command seam every act enters through, because it is a spend:
# it quotes a cost, a half, what is left today and the Day the result lands on,
# and a student confirms that quote before it is charged.
RSpec.describe "committing an Offer" do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:day) { simulation.days.first }
  let(:following) { simulation.days.second }
  let(:organization) { simulation.section.organization }
  let(:dana) { a_user(organization: organization, name: "Dana", email: "dana@wiu.edu") }
  let(:ravi) { a_user(organization: organization, name: "Ravi", email: "ravi@wiu.edu") }
  let(:instructor) do
    a_user(organization: organization, name: "Professor Adeyemi", email: "adeyemi@wiu.edu")
  end

  # There is no roster yet, so a teammate joins the Team by acting for it.
  def a_teammate
    Days::Command.apply(
      act: :spend, side: side, day: day, by: ravi, kind: CaseAction::CONSULT_CLIENT
    )
    ravi
  end

  def stage(by: dana, terms: {"money" => 45_000_00, "apology" => nil}, note: nil)
    Offers::Stage.call(side: side, day: day, by: by, terms: terms, note: note)
  end

  def quote(seconded_by:, on: day)
    Days::Command.quote(
      act: :commit_offer, side: side, day: on, by: dana, seconded_by: seconded_by
    )
  end

  def commit(seconded_by:, by: dana, on: day)
    Days::Command.apply(
      act: :commit_offer, side: side, day: on, by: by, seconded_by: seconded_by
    )
  end

  describe "the quote a student confirms" do
    it "names one point off the exchange half, landing today" do
      teammate = a_teammate
      stage

      confirmation = quote(seconded_by: teammate)

      expect(confirmation).to be_affordable
      expect(confirmation.cost).to eq(1)
      expect(confirmation.half).to eq(DayBudget::EXCHANGE)
      expect(confirmation.landing_day).to eq(day)
      expect(confirmation.remaining_after).to eq(1)
    end

    # A refusal is a refusal rather than a fault, so a Boardroom can leave the
    # commit control present and dead without a failed write.
    it "refuses a Team with nothing on its table" do
      expect(quote(seconded_by: a_teammate).refusal).to eq(:there_is_no_offer_on_the_table)
    end
  end

  it "charges one point of the exchange half and leaves preparation alone" do
    teammate = a_teammate
    stage
    budget = side.budget_on(day)
    prepared = budget.remaining_in(DayBudget::PREPARATION)

    commit(seconded_by: teammate)

    expect(budget.reload.remaining_in(DayBudget::EXCHANGE)).to eq(1)
    expect(budget.remaining_in(DayBudget::PREPARATION)).to eq(prepared)
  end

  # An Offer is worth two numbers, one per Client, because each Client values
  # the Terms privately. So the committed row carries the shape of the deal
  # rather than a figure someone collapsed it into.
  it "carries the full Terms rather than a collapsed value" do
    teammate = a_teammate
    stage(terms: {"money" => 45_000_00, "apology" => nil, "reinstatement" => nil})

    committed = commit(seconded_by: teammate)

    expect(committed.terms.map(&:key)).to contain_exactly("money", "apology", "reinstatement")
    expect(committed.amount_cents).to eq(45_000_00)
    expect(committed.staged_by).to eq(dana)
    expect(committed.seconded_by).to eq(teammate)
  end

  it "leaves the Team's own draft where it is, as the record of what it held" do
    teammate = a_teammate
    stage

    commit(seconded_by: teammate)

    expect(side.staged_offer_on(day)).to be_present
    expect(side.docket(day: day).map(&:act)).to include(Docket::OFFER_STAGED)
  end

  describe "the gate" do
    it "refuses the member who staged the Offer seconding it themselves" do
      a_teammate
      stage

      expect(quote(seconded_by: dana).refusal).to eq(:the_offer_has_not_been_seconded)
    end

    it "refuses a Team whose other members are absent" do
      stage

      expect(quote(seconded_by: nil).refusal).to eq(:the_offer_has_not_been_seconded)
      expect { commit(seconded_by: nil) }.to raise_error(Days::Command::Refused)
    end

    # The Instructor never Seconds on a Team's behalf, so an Offer that lands
    # under a waiver carries no seconder at all.
    it "admits an Offer under an Instructor's waiver, naming nobody as its Second" do
      stage
      Offers::WaiveSecond.call(side: side, day: day, by: instructor)

      committed = commit(seconded_by: nil)

      expect(committed).not_to be_seconded
      expect(committed.staged_by).to eq(dana)
    end

    # A waiver is granted for one Day and read for that Day alone.
    it "does not carry the waiver into the next Day" do
      Offers::WaiveSecond.call(side: side, day: day, by: instructor)
      Days::Commit.call(side: side, day: day, by: dana)
      Days::Commit.call(side: simulation.defendant_side, day: day, by: ravi)
      Offers::Stage.call(side: side, day: following, by: dana, terms: {"money" => 45_000_00})

      expect(quote(seconded_by: nil, on: following).refusal)
        .to eq(:the_offer_has_not_been_seconded)
    end
  end

  describe "at most one committed Offer per Side per Day" do
    it "refuses the second commit on the same Day" do
      teammate = a_teammate
      stage
      commit(seconded_by: teammate)

      expect(quote(seconded_by: teammate).refusal)
        .to eq(:an_offer_has_already_been_committed_today)
      expect { commit(seconded_by: teammate) }.to raise_error(Days::Command::Refused)
    end

    # Two teammates can both read the Day as having no committed Offer, and
    # only the second insert finds the index. The database catches it; asking
    # again turns it back into the refusal the first caller already reads.
    it "turns a lost race into that refusal rather than a fault" do
      teammate = a_teammate
      stage
      command = Days::Command.new(
        act: :commit_offer, side: side, day: day, by: dana, seconded_by: teammate
      )
      expect(command.quote).to be_affordable
      CommittedOffer.create!(side: side, day: day, staged_by: dana, seconded_by: teammate)

      expect { command.apply }.to raise_error(Days::Command::Refused)
      expect(side.budget_on(day).reload.remaining_in(DayBudget::EXCHANGE)).to eq(2)
    end

    # The seam's refusal is the rule a student reads. This is the rule
    # underneath it, which an insert path added later cannot get round.
    it "is a unique index rather than a check the seam remembers" do
      CommittedOffer.create!(side: side, day: day, staged_by: dana, seconded_by: ravi)

      expect {
        CommittedOffer.create!(side: side, day: day, staged_by: ravi, seconded_by: dana)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "a Side whose exchange half is exhausted" do
    before do
      a_teammate
      stage
      # Nothing but an Offer draws on this half yet — the Exhibits that ride one
      # arrive with ticket 9 — so the ledger row that half's spend takes is
      # written straight in, leaving the Side nothing to commit with.
      side.docket_entries.create!(
        day: day, lands_on_day: day, spent_by: ravi,
        case_action: nil, cost: 2, half: DayBudget::EXCHANGE
      )
    end

    it "is refused the commit" do
      expect(quote(seconded_by: ravi).refusal).to eq(:the_budget_cannot_cover_it)
      expect { commit(seconded_by: ravi) }.to raise_error(Days::Command::Refused)
    end

    it "keeps the position on its own table for a Day it can afford" do
      expect { commit(seconded_by: ravi) }.to raise_error(Days::Command::Refused)

      expect(side.staged_offer_on(day)).to be_present
      expect(side.staged_offer_on(day).amount_cents).to eq(45_000_00)
      expect(CommittedOffer.count).to eq(0)
    end
  end

  describe "the Day it implies" do
    it "commits the Side's Day" do
      teammate = a_teammate
      stage

      commit(seconded_by: teammate)

      expect(DayCommitment.find_by(side: side, day: day).committed_by).to eq(dana)
    end

    it "closes the Day when it is the second Side to commit" do
      teammate = a_teammate
      stage
      Days::Commit.call(side: simulation.defendant_side, day: day, by: ravi)

      commit(seconded_by: teammate)

      expect(day.reload).to be_closed
    end

    # The implication runs one way only. A Side that spent its whole Budget on
    # preparation and made no Offer has still finished its Day.
    it "is not implied back: committing the Day creates no Offer" do
      stage

      Days::Commit.call(side: side, day: day, by: dana)

      expect(CommittedOffer.count).to eq(0)
      expect(side.budget_on(day).remaining_in(DayBudget::EXCHANGE)).to eq(2)
    end
  end

  # Check, spend, copy — one transaction. A Team is never charged for a play
  # that half happened.
  it "leaves the Budget and both tables untouched when any step fails" do
    teammate = a_teammate
    stage
    budget = side.budget_on(day)
    before = DayBudget::HALVES.index_with { |half| budget.remaining_in(half) }
    allow(Days::Commit).to receive(:call).and_raise("the Day commit fell over")

    expect { commit(seconded_by: teammate) }.to raise_error("the Day commit fell over")

    expect(DayBudget::HALVES.index_with { |half| budget.reload.remaining_in(half) }).to eq(before)
    expect(CommittedOffer.count).to eq(0)
    expect(CommittedOfferTerm.count).to eq(0)
    expect(side.docket_entries.where(half: DayBudget::EXCHANGE)).to be_empty
    expect(side.staged_offer_on(day)).to be_present
  end

  it "is on the Docket as the spend it is" do
    teammate = a_teammate
    stage

    commit(seconded_by: teammate)

    spend = side.docket(day: day).reverse.find(&:spend?)
    expect(spend.cost).to eq(1)
    expect(spend.half).to eq(DayBudget::EXCHANGE)
    expect(spend.by).to eq(dana)
    expect(spend.lands_on_day).to eq(day)
  end
end
