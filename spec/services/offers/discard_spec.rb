# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offers::Discard do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:day) { simulation.days.first }
  let(:dana) { a_user(organization: simulation.section.organization) }

  it "takes the draft off the Team's own table, leaving nothing behind" do
    Offers::Stage.call(side: side, day: day, by: dana, terms: {"money" => 45_000_00})

    described_class.call(side: side, day: day)

    expect(side.staged_offer_on(day)).to be_nil
    expect(StagedOfferTerm.count).to eq(0)
  end

  it "costs nothing and writes no Docket row" do
    Offers::Stage.call(side: side, day: day, by: dana, terms: {"money" => 45_000_00})
    described_class.call(side: side, day: day)

    expect(side.budget_on(day).reload.remaining_in(DayBudget::PREPARATION)).to eq(8)
    expect(side.docket_entries).to be_empty
  end

  it "is a no-op on a Day with no draft on it" do
    expect { described_class.call(side: side, day: day) }.not_to raise_error
  end
end
