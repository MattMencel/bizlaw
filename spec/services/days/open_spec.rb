# frozen_string_literal: true

require "rails_helper"

RSpec.describe Days::Open do
  it "writes one quota row per Side, sized from the Case's authored reference values" do
    simulation = a_simulation
    day = simulation.days.find_by(ordinal: 2)

    described_class.call(day)

    quotas = DayBudget.where(day: day)
    expect(quotas.count).to eq(2)
    expect(quotas.map(&:side_id)).to match_array(simulation.sides.map(&:id))
    expect(quotas.map(&:preparation_budget)).to all(eq(8))
    expect(quotas.map(&:exchange_budget)).to all(eq(2))
  end

  # The reference Case authors 10 points a Day with an exchange half of two, and
  # a knee at three fifths past which the Day is 2 and 3. Over 10 Days that puts
  # the last flat Day at 6 and the first closing Day at 7.
  describe "the taper past the knee" do
    [
      [1, 8, 2],
      [6, 8, 2],
      [7, 2, 3],
      [10, 2, 3]
    ].each do |ordinal, preparation, exchange|
      it "gives Day #{ordinal} a preparation half of #{preparation} and an exchange half of #{exchange}" do
        simulation = a_simulation
        day = simulation.days.find_by(ordinal: ordinal)

        described_class.call(day)

        quota = DayBudget.find_by!(side: simulation.plaintiff_side, day: day)
        expect(quota.preparation_budget).to eq(preparation)
        expect(quota.exchange_budget).to eq(exchange)
      end
    end
  end

  describe "a quota already written" do
    it "is left alone when the Day is opened again" do
      simulation = a_simulation
      day = simulation.days.find_by(ordinal: 2)
      described_class.call(day)
      quota = DayBudget.find_by!(side: simulation.plaintiff_side, day: day)

      expect { described_class.call(day) }.not_to change(DayBudget, :count)
      expect(quota.reload.updated_at).to eq(quota.updated_at)
    end

    it "survives a Section that changes its Budget size mid-Simulation" do
      simulation = a_simulation
      played = simulation.days.find_by(ordinal: 2)
      described_class.call(played)

      simulation.section.update!(budget_per_day: 6)
      described_class.call(simulation.days.find_by(ordinal: 3))

      expect(DayBudget.find_by!(side: simulation.plaintiff_side, day: played).preparation_budget)
        .to eq(8)
      expect(DayBudget.find_by!(side: simulation.plaintiff_side, day: simulation.days.find_by(ordinal: 3)).preparation_budget)
        .to eq(4)
    end

    it "leaves the exchange half alone when the Section shrinks the Budget, because it is a count" do
      simulation = a_simulation
      simulation.section.update!(budget_per_day: 6)

      described_class.call(simulation.days.find_by(ordinal: 2))

      expect(DayBudget.find_by!(side: simulation.plaintiff_side, day: simulation.days.find_by(ordinal: 2)).exchange_budget)
        .to eq(2)
    end
  end
end
