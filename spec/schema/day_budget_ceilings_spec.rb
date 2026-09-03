# frozen_string_literal: true

require "rails_helper"

# ADR 0002: the Action Budget is the one ceiling in the game whose behaviour at
# the boundary is a refusal, so it is a CHECK rather than a computed value. The
# halves are two ceilings, so the row carries two counter pairs and two CHECKs.
#
# These specs write past each ceiling at the level below the models and expect
# the database to raise — a constraint is only doing the job the trigger is
# trusted for if it actually refuses.
RSpec.describe "the Action Budget's ceilings" do
  let(:simulation) { a_simulation }
  let(:day) { simulation.days.first }
  let(:quota) { Days::Open.call(day).first }

  it "refuses a preparation half spent past its budget" do
    expect { quota.update_column(:preparation_spent, quota.preparation_budget + 1) }
      .to raise_error(ActiveRecord::StatementInvalid, /day_budgets_preparation_within_budget/)
  end

  it "refuses an exchange half spent past its budget" do
    expect { quota.update_column(:exchange_spent, quota.exchange_budget + 1) }
      .to raise_error(ActiveRecord::StatementInvalid, /day_budgets_exchange_within_budget/)
  end

  it "allows either half spent to exactly its budget" do
    quota.update_columns(
      preparation_spent: quota.preparation_budget,
      exchange_spent: quota.exchange_budget
    )

    expect(quota.reload.preparation_spent).to eq(quota.preparation_budget)
  end

  it "holds one quota row per Side per Day" do
    expect { DayBudget.create!(side: quota.side, day: day, preparation_budget: 8, exchange_budget: 2) }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "refuses a quota whose exchange half cannot play an Offer with an Exhibit behind it" do
    expect {
      DayBudget.create!(side: simulation.defendant_side, day: day,
        preparation_budget: 8, exchange_budget: 1)
    }.to raise_error(ActiveRecord::StatementInvalid,
      /day_budgets_exchange_budget_plays_an_offer/)
  end

  it "opens both halves at nothing spent" do
    expect(quota.preparation_spent).to eq(0)
    expect(quota.exchange_spent).to eq(0)
  end
end
