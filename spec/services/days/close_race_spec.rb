# frozen_string_literal: true

require "rails_helper"

# Two commits landing at once leave one closed Day and one set of next-Day
# quota rows.
#
# What this does *not* do is isolate the compare-and-set as the thing that
# achieved it, and the honest note is worth more than the claim: swapping
# `Days::Close`'s conditional UPDATE for a load-then-save keeps this file green.
# On SQLite one writer holds the lock at a time, and `Days::Open` and
# `Days::Land` are independently idempotent by unique index, so a second closer
# has nothing left to duplicate. Distinguishing the two would mean instrumenting
# the service to hold a transaction open, which is a worse spec than this one.
#
# The compare-and-set is ADR 0002's, it is what a second database without
# SQLite's single-writer serialization would need, and the observable half of
# it — that the losing caller is told it lost, which is what `FireDeadlines`
# reports from — is asserted deterministically in `close_spec.rb`.
#
# Real threads need real connections, so this group runs outside the
# transaction every other spec runs inside and empties the tables itself
# afterwards. It is the only group in the suite that does.
RSpec.describe "two Sides finishing a Day at the same moment" do
  self.use_transactional_tests = false

  after do
    ActiveRecord::Base.connection.disable_referential_integrity do
      (ActiveRecord::Base.connection.tables - %w[schema_migrations ar_internal_metadata])
        .each { |table| ActiveRecord::Base.connection.delete("DELETE FROM #{table}") }
    end
  end

  # Both threads are held at the barrier until both have arrived, so the second
  # commit and whatever the first is still doing genuinely overlap.
  def in_parallel(&block)
    barrier = Concurrent::CyclicBarrier.new(2)

    [0, 1].map { |index|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          barrier.wait
          block.call(index)
        end
      end
    }.map(&:value)
  end

  let(:simulation) { a_simulation }
  let(:day) { simulation.days.first }
  let(:following) { simulation.days.second }

  it "closes the Day once and opens the next one once, however the two commits interleave" do
    organization = simulation.section.organization
    sides = [simulation.plaintiff_side, simulation.defendant_side]
    students = sides.map.with_index { |_, index|
      a_user(organization: organization, name: "Student #{index}", email: "student#{index}@example.edu")
    }

    # Bought on Day 1 with a lead time of one, so it lands as Day 2 opens — the
    # other half of the open work, and the half a second closer could double.
    Days::Command.apply(
      act: :spend, side: sides[0], day: day, by: students[0],
      kind: CaseAction::REQUEST_DOCUMENTS
    )

    in_parallel do |index|
      Days::Commit.call(side: sides[index], day: day, by: students[index])
    end

    expect(DayCommitment.where(day: day).count).to eq(2)
    expect(day.reload).to be_closed
    expect(DayBudget.where(day: following).count).to eq(2)
    expect(CaseFileDocument.where(day: following).count).to eq(1)
  end

  it "hands the affected row to exactly one of two callers racing the close itself" do
    outcomes = in_parallel { Days::Close.call(day) }

    expect(outcomes).to match_array([true, false])
    expect(DayBudget.where(day: following).count).to eq(2)
  end
end
