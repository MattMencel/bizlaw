# frozen_string_literal: true

require "rails_helper"

# The one close path. ADR 0002 specifies the mechanism — `UPDATE days SET
# closed_at = ? WHERE id = ? AND closed_at IS NULL` — and all three callers go
# through it: the second Side's commit, the deadline sweep and an Instructor
# force-close. Exactly one writer gets an affected row and does the open work in
# the same transaction.
RSpec.describe Days::Close do
  let(:simulation) { a_simulation }
  let(:day) { simulation.days.first }
  let(:following) { simulation.days.second }

  it "closes an open Day and tells the caller it was the one that closed it" do
    expect(described_class.call(day)).to be(true)
    expect(day.reload).to be_closed
  end

  it "writes both Sides' quota rows for the next Day in the same transaction" do
    expect { described_class.call(day) }
      .to change { DayBudget.where(day: following).count }.from(0).to(2)
  end

  it "materialises the Actions that land on the next Day" do
    student = a_user(organization: simulation.section.organization)
    Days::Command.apply(
      act: :spend, side: simulation.plaintiff_side, day: day, by: student,
      kind: CaseAction::REQUEST_DOCUMENTS
    )

    expect { described_class.call(day) }
      .to change { CaseFileDocument.where(side: simulation.plaintiff_side).count }.by(1)
  end

  # The Instructor force-closing a stalled Day is this call and nothing beside
  # it: there is one close path in the codebase, so the Instructor's power is
  # the absence of a second one.
  it "closes a Day neither Side has committed" do
    expect(described_class.call(day)).to be(true)
    expect(DayCommitment.where(day: day)).to be_empty
    expect(following.reload.budgets.count).to eq(2)
  end

  describe "the compare-and-set" do
    it "tells the second caller it did not close the Day" do
      described_class.call(day)

      expect(described_class.call(day)).to be(false)
    end

    it "leaves the closing time the first caller wrote" do
      described_class.call(day, at: Time.utc(2026, 3, 2, 17))

      described_class.call(day, at: Time.utc(2026, 3, 3, 17))

      expect(day.reload.closed_at).to eq(Time.utc(2026, 3, 2, 17))
    end

    it "does the next Day's open work exactly once" do
      described_class.call(day)
      quotas = DayBudget.where(day: following).order(:id).to_a

      described_class.call(day)

      expect(DayBudget.where(day: following).order(:id).map(&:id)).to eq(quotas.map(&:id))
      expect(quotas.map { |quota| quota.reload.updated_at })
        .to eq(quotas.map(&:updated_at))
    end
  end

  # The close and the open are one transaction, so a Simulation cannot come to
  # hold a Day that ended without the next one starting.
  it "rolls the close back when the next Day's open fails" do
    day # laid out before the stub, because Day 1's own open goes through here too
    allow(Days::Open).to receive(:call).and_raise("the quota could not be written")

    expect { described_class.call(day) }.to raise_error("the quota could not be written")
    expect(day.reload).to be_open
  end

  describe "the last Day" do
    let(:day) { simulation.days.last }

    it "closes without attempting to open a Day that does not exist" do
      expect(described_class.call(day)).to be(true)
      expect(day.reload).to be_closed
    end

    it "writes no further quota rows" do
      day # the Simulation, and Day 1's own quota, exist before the count is taken

      expect { described_class.call(day) }.not_to change(DayBudget, :count)
    end
  end

  describe "the Budget that was left" do
    it "is gone: the next Day's row carries the fresh quota and nothing more" do
      student = a_user(organization: simulation.section.organization)
      Days::Command.apply(
        act: :spend, side: simulation.plaintiff_side, day: day, by: student,
        kind: CaseAction::RETAIN_EXPERT
      )

      described_class.call(day)

      quota = simulation.plaintiff_side.budget_on(following)
      expect(quota.preparation_budget).to eq(8)
      expect(quota.preparation_spent).to eq(0)
    end

    it "cannot be spent on the Day after it closed" do
      side = simulation.plaintiff_side
      student = a_user(organization: simulation.section.organization)
      described_class.call(day)

      quote = Days::Command.new(
        act: :spend, side: side, day: day.reload, by: student,
        kind: CaseAction::CONSULT_CLIENT
      ).quote

      expect(quote).to be_refused
      expect(quote.refusal).to eq(:the_day_has_closed)
    end
  end
end
