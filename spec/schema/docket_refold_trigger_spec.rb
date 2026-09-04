# frozen_string_literal: true

require "rails_helper"

# ADR 0002: `day_budgets`'s spent counters are maintained by an `AFTER INSERT`
# trigger on `docket_entries` that **re-folds** the sum from the Docket rather
# than incrementing it. A fold cannot drift the way a lost or doubled delta can,
# and a trigger cannot be bypassed by an insert path added later that forgot to
# check — which is the actual exposure, since SQLite serializes writers and had
# already killed the race.
#
# These specs insert Docket rows behind the command seam on purpose. The seam is
# where the rules live; the trigger is what holds when something skips it.
RSpec.describe "the Docket's re-fold trigger" do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:day) { simulation.days.first }
  let(:student) { a_user(organization: simulation.section.organization) }
  let(:budget) { side.budget_on(day) }

  def a_docket_row(kind, cost: nil)
    action = simulation.case_version.actions.find_by!(kind: kind)
    side.docket_entries.create!(
      day: day, lands_on_day: day, spent_by: student, case_action: action,
      cost: cost || action.cost, half: action.half
    )
  end

  it "leaves preparation_spent equal to a fold of the Docket" do
    a_docket_row(CaseAction::CONSULT_CLIENT)
    a_docket_row(CaseAction::REQUEST_DOCUMENTS)
    a_docket_row(CaseAction::DEPOSE_WITNESS)

    expect(budget.reload.preparation_spent)
      .to eq(DocketEntry.where(side: side, day: day, half: DayBudget::PREPARATION).sum(:cost))
    expect(budget.preparation_spent).to eq(6)
  end

  # An incrementing trigger would land on 3 here; a re-folding one recomputes
  # the whole sum and lands on 4. That difference is the whole point.
  it "re-folds the sum rather than incrementing it, so a drifted counter heals" do
    a_docket_row(CaseAction::RESEARCH_PRECEDENT)
    budget.update_column(:preparation_spent, 1)

    a_docket_row(CaseAction::REQUEST_DOCUMENTS)

    expect(budget.reload.preparation_spent).to eq(4)
  end

  it "folds each Side's own Docket and no one else's" do
    a_docket_row(CaseAction::RETAIN_EXPERT)

    expect(simulation.defendant_side.budget_on(day).preparation_spent).to eq(0)
  end

  it "folds each Day's own Docket and no one else's" do
    Days::Open.call(simulation.days.second)
    a_docket_row(CaseAction::RETAIN_EXPERT)

    expect(side.budget_on(simulation.days.second).preparation_spent).to eq(0)
  end

  it "refuses a Docket row that would fold the preparation half past its budget" do
    a_docket_row(CaseAction::RETAIN_EXPERT)
    a_docket_row(CaseAction::DEPOSE_WITNESS)

    expect { a_docket_row(CaseAction::CONSULT_CLIENT) }
      .to raise_error(ActiveRecord::StatementInvalid, /day_budgets_preparation_within_budget/)
  end

  it "leaves the Budget where it was when the fold is refused" do
    a_docket_row(CaseAction::RETAIN_EXPERT)

    begin
      a_docket_row(CaseAction::RETAIN_EXPERT)
    rescue ActiveRecord::StatementInvalid
      nil
    end

    expect(budget.reload.preparation_spent).to eq(5)
    expect(DocketEntry.where(side: side, day: day).count).to eq(1)
  end

  # Without this the fold would silently no-op and `Days::Open` would later
  # write that Day's quota at nothing spent, handing the points back.
  it "refuses a Docket row for a Day that has not opened, so no fold is lost" do
    unopened = simulation.days.second
    action = simulation.case_version.actions.find_by!(kind: CaseAction::CONSULT_CLIENT)

    expect {
      side.docket_entries.create!(
        day: unopened, lands_on_day: unopened, spent_by: student,
        case_action: action, cost: action.cost, half: action.half
      )
    }.to raise_error(ActiveRecord::StatementInvalid, /docket_entries_need_an_opened_day/)
  end

  # Remaining Budget expires at close, and this is the half of that the schema
  # holds: the quota row survives the close, so without this a caller handed
  # yesterday's Day could still fold points out of it.
  it "refuses a Docket row for a Day that has closed, so the Budget cannot outlive it" do
    Days::Close.call(day)
    action = simulation.case_version.actions.find_by!(kind: CaseAction::CONSULT_CLIENT)

    expect {
      side.docket_entries.create!(
        day: day, lands_on_day: day, spent_by: student,
        case_action: action, cost: action.cost, half: action.half
      )
    }.to raise_error(ActiveRecord::StatementInvalid, /docket_entries_need_an_unclosed_day/)
  end

  it "leaves the exchange half at nothing spent, because nothing draws on it yet" do
    a_docket_row(CaseAction::DEPOSE_WITNESS)

    expect(budget.reload.exchange_spent).to eq(0)
  end
end
