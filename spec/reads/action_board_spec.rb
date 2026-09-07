# frozen_string_literal: true

require "rails_helper"

# *What we could do*, opposite the Case File's *what we know* and the Docket's
# *what we have done*. Every Action is on it from Day 1, priced: hiding what an
# Action costs makes the Budget unplannable, and planning the Budget is the
# lesson.
RSpec.describe ActionBoard do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:day) { simulation.days.first }
  let(:student) { a_user(organization: simulation.section.organization) }

  def board(on: day) = described_class.for(side, day: on)

  def entry(kind, on: day) = board(on: on).entries.find { |row| row.kind == kind }

  it "carries every Action the Case authors, from Day 1" do
    expect(board.entries.map(&:kind)).to match_array(simulation.case_version.actions.map(&:kind))
  end

  it "reads cheapest first" do
    expect(board.entries.map(&:cost)).to eq(board.entries.map(&:cost).sort)
  end

  it "prices each Action with its cost, its half and its lead time" do
    expect(entry(CaseAction::DEPOSE_WITNESS)).to have_attributes(
      cost: 3, half: DayBudget::PREPARATION, lead_time_days: 2
    )
  end

  it "names the Day each Action's result would land on" do
    expect(entry(CaseAction::DEPOSE_WITNESS).landing_day.ordinal).to eq(3)
    expect(entry(CaseAction::CONSULT_CLIENT).landing_day.ordinal).to eq(1)
  end

  it "says which Actions land on the Day they are bought" do
    expect(entry(CaseAction::CONSULT_CLIENT)).to be_lands_today
    expect(entry(CaseAction::REQUEST_DOCUMENTS)).not_to be_lands_today
  end

  # A control the seam would refuse is disabled rather than absent, and it keeps
  # its price: a Team plans against what an Action costs whether or not it can
  # afford it today.
  describe "an Action the Day cannot cover" do
    before do
      Days::Command.apply(act: :spend, side: side, day: day, by: student,
        kind: CaseAction::RETAIN_EXPERT)
    end

    it "stays on the board, priced" do
      expect(entry(CaseAction::RETAIN_EXPERT)).to have_attributes(cost: 5, lead_time_days: 2)
    end

    it "is refused rather than hidden, with the reason" do
      expect(entry(CaseAction::RETAIN_EXPERT)).not_to be_affordable
      expect(entry(CaseAction::RETAIN_EXPERT).refusal).to eq(:the_budget_cannot_cover_it)
    end

    it "leaves what the half still covers affordable" do
      expect(board.affordable.map(&:kind)).to include(CaseAction::CONSULT_CLIENT)
      expect(board.affordable.map(&:kind)).not_to include(CaseAction::RETAIN_EXPERT)
    end
  end

  # Burning points on discovery that can never arrive is what the refusal exists
  # to prevent, and the board is where a Team sees it coming.
  it "refuses an Action whose result would land past the last Day" do
    last = simulation.days.find_by!(ordinal: 10)

    expect(entry(CaseAction::DEPOSE_WITNESS, on: last).refusal)
      .to eq(:the_result_would_land_past_the_last_day)
    expect(entry(CaseAction::DEPOSE_WITNESS, on: last).cost).to eq(3)
  end

  # The price a control renders and the price a student is charged come from one
  # code path, so they cannot drift.
  it "quotes what the seam charges" do
    quoted = entry(CaseAction::DEPOSE_WITNESS)
    charged = Days::Command.apply(act: :spend, side: side, day: day, by: student,
      kind: CaseAction::DEPOSE_WITNESS)

    expect(charged.cost).to eq(quoted.cost)
    expect(charged.lands_on_day).to eq(quoted.landing_day)
  end

  it "writes nothing" do
    expect { board.entries }.not_to change(DocketEntry, :count)
    expect(side.budget_on(day).reload.remaining_in(DayBudget::PREPARATION)).to eq(8)
  end
end
