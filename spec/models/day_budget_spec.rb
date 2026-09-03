# frozen_string_literal: true

require "rails_helper"

RSpec.describe DayBudget do
  let(:simulation) { a_simulation }
  let(:day) { simulation.days.first }

  def a_quota(**overrides)
    described_class.new(
      {side: simulation.plaintiff_side, day: day,
       preparation_budget: 8, exchange_budget: 2}.merge(overrides)
    )
  end

  # The floor the database refuses at is the floor the model refuses at, so a
  # quota below it comes back as a validation error rather than as a CHECK
  # violation raised from inside an insert.
  describe "the exchange half's floor" do
    it "refuses a half that cannot play an Offer with an Exhibit behind it" do
      quota = a_quota(exchange_budget: 1)

      expect(quota).not_to be_valid
      expect(quota.errors[:exchange_budget]).to be_present
    end

    it "refuses a half of nothing" do
      expect(a_quota(exchange_budget: 0)).not_to be_valid
    end

    it "accepts the two points an Offer with one Exhibit costs" do
      expect(a_quota(exchange_budget: 2)).to be_valid
    end
  end

  # The preparation half has no floor but zero: the taper collapses it to
  # roughly the price of a Consult past the knee, and a Section may shrink it
  # to nothing without the Day becoming unplayable.
  describe "the preparation half" do
    it "accepts nothing left to prepare with" do
      expect(a_quota(preparation_budget: 0)).to be_valid
    end

    it "refuses less than nothing" do
      expect(a_quota(preparation_budget: -1)).not_to be_valid
    end
  end
end
