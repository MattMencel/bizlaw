# frozen_string_literal: true

require "rails_helper"

# The clip is what a shift owns alone. Everything else about a discovery — who
# finds it, when it lands, how often — belongs to `Days::Land`.
RSpec.describe ClientShift do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:day) { simulation.days.first }

  def a_shift(fraction, source_ref: rand(1..1_000_000), **overrides)
    described_class.create!(
      side: side, day: day,
      source_kind: described_class::UNFAVORABLE_DISCOVERY,
      source_ref: source_ref,
      requested_fraction: fraction,
      **overrides
    )
  end

  it "applies the whole of a shift a fresh bound can absorb" do
    expect(a_shift(0.25).applied_fraction).to eq(0.25)
  end

  # The applied figure is the model's. A caller that hands one in has it
  # discarded rather than trusted, which is what keeps the CHECK underneath a
  # proof of the clip and not merely a proof of the caller.
  it "computes the applied fraction rather than taking the one it was given" do
    expect(a_shift(0.1, applied_fraction: 0.99).applied_fraction).to eq(0.1)
  end

  # Shifts stack additively against one bound, so the second is measured
  # against what the first left rather than against the whole.
  it "measures each shift against the travel the ones before it left" do
    a_shift(0.25)
    second = a_shift(0.9)

    expect(second.applied_fraction).to eq(0.75)
    expect(side.bound_consumed).to eq(1)
  end

  describe "a bound part way through its travel" do
    before { a_shift(0.8) }

    it "clips a shift to the travel that remains, and still lands it" do
      shift = a_shift(0.5)

      expect(shift.requested_fraction).to eq(0.5)
      expect(shift.applied_fraction).to eq(0.2)
      expect(side.bound_consumed).to eq(1)
    end
  end

  describe "an exhausted bound" do
    before { a_shift(1) }

    it "clips the shift to nothing and still lands it, rather than raising" do
      shift = a_shift(0.3)

      expect(shift).to be_persisted
      expect(shift.applied_fraction).to be_zero
    end

    it "leaves the bound where it was rather than overshooting it" do
      a_shift(0.3)

      expect(side.bound_consumed).to eq(1)
      expect(side.bound_remaining).to be_zero
    end
  end

  # Player-caused movement is a ratchet: it only ever moves a reservation point
  # toward settleability. Only an Event moves one back outward, and it is not
  # built here.
  it "refuses a shift that reaches back outward" do
    expect { a_shift(-0.25) }.to raise_error(ActiveRecord::RecordInvalid, /Requested fraction/)
  end

  it "refuses a shift larger than the whole of a Client's travel" do
    expect { a_shift(1.5) }.to raise_error(ActiveRecord::RecordInvalid, /Requested fraction/)
  end

  it "refuses a source the ledger does not know" do
    expect { a_shift(0.25, source_kind: "a_hunch") }
      .to raise_error(ActiveRecord::RecordInvalid, /Source kind/)
  end

  describe "the bound each Side draws on" do
    it "is the Side's own Client's, and no one else's" do
      a_shift(0.25)

      expect(simulation.defendant_side.bound_consumed).to be_zero
      expect(simulation.defendant_side.bound_remaining).to eq(1)
    end

    it "is the one thing about a Client authored as money" do
      expect(side.client.role).to eq(Side::PLAINTIFF)
      expect(side.client.bound_cents).to eq(40_000_00)
    end
  end
end
