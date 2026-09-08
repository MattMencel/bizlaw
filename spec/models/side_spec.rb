# frozen_string_literal: true

require "rails_helper"

RSpec.describe Side do
  it "holds one Side per role in a Simulation, so there can never be a third" do
    simulation = a_simulation

    expect { simulation.sides.create!(role: Side::PLAINTIFF) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it "is capped at two by unique index, not only by validation" do
    simulation = a_simulation
    third = simulation.sides.build(role: Side::PLAINTIFF, organization_id: simulation.organization_id)

    expect { third.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    expect(simulation.sides.reload.count).to eq(2)
  end

  it "refuses a role the dispute does not have" do
    simulation = a_simulation

    expect { simulation.sides.create!(role: "arbitrator") }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  # The only read a Team ever gets on how far their own Client has moved, and
  # what a Consult is charged for. A fold over the shift ledger with an instant
  # on it and never a column — ADR 0006.
  describe "the Reaction Band" do
    let(:simulation) { a_simulation }
    let(:side) { simulation.plaintiff_side }
    let(:day) { simulation.days.first }

    def a_shift(fraction, at: Time.current)
      side.client_shifts.create!(
        day: day,
        source_kind: ClientShift::UNFAVORABLE_DISCOVERY,
        source_ref: rand(1..1_000_000),
        requested_fraction: fraction,
        created_at: at
      )
    end

    it "reads a Client who has not moved as firm" do
      expect(side.reaction_band(as_of: Time.current)).to eq(CaseClientBand::FIRM)
    end

    # The edge is measured late — around four fifths — because an early one is a
    # Client crying wolf: the Team reacts while nothing has really happened.
    it "still reads firm short of the authored edge" do
      a_shift(0.75)

      expect(side.reaction_band(as_of: Time.current)).to eq(CaseClientBand::FIRM)
    end

    it "crosses to ready at the edge the Case authored" do
      a_shift(0.8)

      expect(side.reaction_band(as_of: Time.current)).to eq(CaseClientBand::READY)
    end

    # A band is a bucket, so it is imprecise near the ends by construction: a
    # Client at the edge and one that has exhausted the bound read the same.
    it "reads an exhausted bound as ready and nothing louder" do
      a_shift(1)

      expect(side.reaction_band(as_of: Time.current)).to eq(CaseClientBand::READY)
    end

    # The horizon is the whole of ADR 0006. A Consult bought on Day 3 and read
    # again on Day 5 answers what the Client said then; a band that moves is
    # shown at the next Consult, not the moment it moves.
    it "answers as of the instant it is asked about, not as of now" do
      consulted_at = 1.hour.ago
      a_shift(0.9)

      expect(side.reaction_band(as_of: consulted_at)).to eq(CaseClientBand::FIRM)
      expect(side.reaction_band(as_of: Time.current)).to eq(CaseClientBand::READY)
    end

    # A shift written in the same instant is inside the horizon. Nothing can
    # reach that tie for a Consult — a Consult yields no paper and `Cases::
    # Import` refuses the Case that would author some — but the boundary is
    # inclusive rather than accidental.
    it "counts a shift written at the instant asked about" do
      moment = Time.current
      a_shift(0.9, at: moment)

      expect(side.reaction_band(as_of: moment)).to eq(CaseClientBand::READY)
    end

    it "reads only its own Client, never the Side across the table" do
      a_shift(0.9)

      expect(simulation.defendant_side.reaction_band(as_of: Time.current))
        .to eq(CaseClientBand::FIRM)
    end
  end
end
