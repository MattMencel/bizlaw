# frozen_string_literal: true

require "rails_helper"

# A Side commits its Day by declaring itself finished with it. The second commit
# is what closes the Day, and it closes it through the one compare-and-set.
RSpec.describe Days::Commit do
  let(:simulation) { a_simulation }
  let(:organization) { simulation.section.organization }
  let(:day) { simulation.days.first }
  let(:following) { simulation.days.second }
  let(:student) { a_user(organization: organization) }
  let(:teammate) { a_user(organization: organization, name: "Ravi Menon", email: "ravi@example.edu") }

  it "records the commit against the Side, naming the member who declared it" do
    commitment = described_class.call(side: simulation.plaintiff_side, day: day, by: student)

    expect(commitment.side).to eq(simulation.plaintiff_side)
    expect(commitment.day).to eq(day)
    expect(commitment.committed_by).to eq(student)
  end

  it "leaves the Day open while one Side has still not committed" do
    described_class.call(side: simulation.plaintiff_side, day: day, by: student)

    expect(day.reload).to be_open
    expect(DayBudget.where(day: following)).to be_empty
  end

  it "closes the Day when the second Side commits" do
    described_class.call(side: simulation.plaintiff_side, day: day, by: student)
    described_class.call(side: simulation.defendant_side, day: day, by: teammate)

    expect(day.reload).to be_closed
    expect(DayBudget.where(day: following).count).to eq(2)
  end

  # Three students looking at the same button is the ordinary case, so the
  # second press is idempotent by unique index rather than an error.
  describe "a Side committing a Day it has already committed" do
    it "writes no second row and keeps the Attribution of the first" do
      first = described_class.call(side: simulation.plaintiff_side, day: day, by: student)

      again = described_class.call(side: simulation.plaintiff_side, day: day, by: teammate)

      expect(again.id).to eq(first.id)
      expect(again.committed_by).to eq(student)
      expect(DayCommitment.where(day: day).count).to eq(1)
    end

    it "does not close the Day on its own" do
      described_class.call(side: simulation.plaintiff_side, day: day, by: student)
      described_class.call(side: simulation.plaintiff_side, day: day, by: teammate)

      expect(day.reload).to be_open
    end
  end

  it "refuses a Day that has already closed" do
    Days::Close.call(day)

    expect { described_class.call(side: simulation.plaintiff_side, day: day.reload, by: student) }
      .to raise_error(Days::Commit::DayClosed)
  end
end
