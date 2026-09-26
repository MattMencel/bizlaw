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

  # The service reads a Day it holds in memory, which a force-close landing on
  # another connection has already moved on from. The trigger is the rule a
  # stale object cannot get past.
  it "refuses a commitment on a closed Day even from a Side holding a stale Day" do
    stale = simulation.days.find(day.id)
    Days::Close.call(day)

    expect { DayCommitment.create!(side: simulation.plaintiff_side, day: stale, committed_by: student) }
      .to raise_error(ActiveRecord::StatementInvalid, /day_commitments_need_an_unclosed_day/)
  end

  # The same race through the seam: the Day passed the read and landed on the
  # trigger. It comes back as the seam's own refusal rather than a fault.
  it "turns a close that raced it into the seam's own refusal" do
    stale = simulation.days.find(day.id)
    Days::Close.call(day)

    expect { described_class.call(side: simulation.plaintiff_side, day: stale, by: student) }
      .to raise_error(Days::Commit::DayClosed)
    expect(DayCommitment.where(day: day)).to be_empty
  end

  # The plaintiff sends an Offer under a waiver and the defendant takes it under
  # another, which settles the run and closes the Day it landed on.
  def settle
    instructor = a_user(organization: organization, name: "Professor Adeyemi", email: "adeyemi@example.edu")
    plaintiff = simulation.plaintiff_side
    Offers::Stage.call(side: plaintiff, day: day, by: student, terms: {"money" => 45_000_00})
    Offers::WaiveSecond.call(side: plaintiff, day: day, by: instructor)
    offer = Days::Command.apply(act: :commit_offer, side: plaintiff, day: day, by: student, seconded_by: nil)
    Offers::WaiveSecond.call(side: simulation.defendant_side, day: day, by: instructor)
    Offers::Accept.call(offer: offer, side: simulation.defendant_side, day: day, by: teammate)
    day.reload
  end

  it "refuses a settled run" do
    settle

    expect { described_class.call(side: simulation.plaintiff_side, day: day, by: student) }
      .to raise_error(Simulation::AlreadySettled)
  end

  # The block prints its obstacle from the list `call` raises from, so the
  # control and the write are one rule.
  describe ".refusal_for" do
    it "answers nil where the commit would land" do
      expect(described_class.refusal_for(side: simulation.plaintiff_side, day: day, by: student))
        .to be_nil
    end

    it "names a closed Day" do
      Days::Close.call(day)

      expect(described_class.refusal_for(side: simulation.plaintiff_side, day: day.reload, by: student))
        .to eq(:the_day_has_closed)
    end

    it "names a settled run ahead of the Day it closed" do
      settle

      expect(described_class.refusal_for(side: simulation.plaintiff_side, day: day, by: student))
        .to eq(:the_simulation_has_settled)
    end
  end

  # Whether this commit would be the second, and so close the Day. The stub says
  # that first, because it is the consequence.
  describe "#closes_the_day?" do
    it "is false while the other Side has not committed" do
      expect(described_class.new(side: simulation.plaintiff_side, day: day, by: student))
        .not_to be_closes_the_day
    end

    it "is true once the other Side has" do
      described_class.call(side: simulation.defendant_side, day: day, by: teammate)

      expect(described_class.new(side: simulation.plaintiff_side, day: day, by: student))
        .to be_closes_the_day
    end
  end
end
