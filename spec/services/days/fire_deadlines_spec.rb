# frozen_string_literal: true

require "rails_helper"

# The Instructor's clock. A deadline that fires closes the Day exactly as a
# second commit would, so this sweep resolves *which* Days are due and hands
# each to the one close path.
RSpec.describe Days::FireDeadlines do
  let(:simulation) { a_simulation }
  let(:day) { simulation.days.first }
  let(:deadline) { Time.utc(2026, 3, 2, 17) }

  it "closes a Day whose deadline has passed" do
    day.update!(deadline_at: deadline)

    expect(described_class.call(at: deadline + 1.minute)).to eq([day])
    expect(day.reload).to be_closed
  end

  it "does the next Day's open work, because it closed through the same path" do
    day.update!(deadline_at: deadline)

    described_class.call(at: deadline + 1.minute)

    expect(DayBudget.where(day: simulation.days.second).count).to eq(2)
  end

  it "leaves a Day whose deadline has not arrived" do
    day.update!(deadline_at: deadline)

    expect(described_class.call(at: deadline - 1.minute)).to be_empty
    expect(day.reload).to be_open
  end

  it "leaves a Day carrying no deadline" do
    expect(described_class.call(at: deadline)).to be_empty
    expect(day.reload).to be_open
  end

  it "passes over a Day that has already closed" do
    day.update!(deadline_at: deadline)
    Days::Close.call(day)

    expect(described_class.call(at: deadline + 1.minute)).to be_empty
  end
end

RSpec.describe Days::ExtendDeadline do
  let(:simulation) { a_simulation }
  let(:day) { simulation.days.first }
  let(:deadline) { Time.utc(2026, 3, 2, 17) }

  it "moves a Day's deadline later" do
    day.update!(deadline_at: deadline)

    described_class.call(day, to: deadline + 1.day)

    expect(day.reload.deadline_at).to eq(deadline + 1.day)
  end

  it "sets a first deadline on a Day that carried none" do
    described_class.call(day, to: deadline)

    expect(day.reload.deadline_at).to eq(deadline)
  end

  # Pulling a deadline back would silently expire a Day a Team is mid-way
  # through, and ending a Day early is what the force-close is for.
  it "refuses to pull a deadline back" do
    day.update!(deadline_at: deadline)

    expect { described_class.call(day, to: deadline - 1.hour) }
      .to raise_error(Days::ExtendDeadline::NotAnExtension)
    expect(day.reload.deadline_at).to eq(deadline)
  end

  it "refuses a move to the deadline the Day already carries" do
    day.update!(deadline_at: deadline)

    expect { described_class.call(day, to: deadline) }
      .to raise_error(Days::ExtendDeadline::NotAnExtension)
  end
end
