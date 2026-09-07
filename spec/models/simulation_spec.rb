# frozen_string_literal: true

require "rails_helper"

# A run ends in exactly one of two ways — a settlement, or Arbitration when the
# Days run out. This is the first of them, and it is a fold over
# `offer_acceptances` rather than a status column: there is no status column
# anywhere, per ADR 0002.
RSpec.describe Simulation do
  let(:simulation) { a_simulation }
  let(:offering) { simulation.plaintiff_side }
  let(:accepting) { simulation.defendant_side }
  let(:day) { simulation.days.first }
  let(:organization) { simulation.section.organization }
  let(:dana) { a_user(organization: organization, name: "Dana", email: "dana@wiu.edu") }
  let(:ravi) { a_user(organization: organization, name: "Ravi", email: "ravi@wiu.edu") }
  let(:kofi) { a_user(organization: organization, name: "Kofi", email: "kofi@wiu.edu") }
  let(:noor) { a_user(organization: organization, name: "Noor", email: "noor@wiu.edu") }

  # There is no roster yet, so a member joins a Team by acting for it.
  def a_member_of(side, person)
    Days::Command.apply(
      act: :spend, side: side, day: day, by: person, kind: CaseAction::CONSULT_CLIENT
    )
    person
  end

  def a_settlement
    a_member_of(offering, ravi)
    a_member_of(accepting, noor)
    Offers::Stage.call(side: offering, day: day, by: dana, terms: {"money" => 45_000_00})
    offer = Days::Command.apply(
      act: :commit_offer, side: offering, day: day, by: dana, seconded_by: ravi
    )
    Offers::Accept.call(offer: offer, side: accepting, day: day, by: kofi, seconded_by: noor)
  end

  describe "#settled?" do
    it "is false for a run nobody has settled" do
      expect(simulation).not_to be_settled
    end

    it "is true once an Acceptance has landed" do
      a_settlement

      expect(simulation.reload).to be_settled
    end

    # A Section runs many concurrent Simulations of one Case. The fold reaches
    # through this run's own Sides, so another Team settling on Tuesday says
    # nothing about a Team still playing on Wednesday.
    it "says nothing about another run in the same Section" do
      a_settlement
      concurrent = Simulations::Create.call(
        section: simulation.section, case_version: simulation.case_version
      )

      expect(concurrent).not_to be_settled
    end
  end

  describe "#settlement" do
    it "is nil while the run is still live" do
      expect(simulation.settlement).to be_nil
    end

    it "is the Acceptance that ended it" do
      acceptance = a_settlement

      expect(simulation.reload.settlement).to eq(acceptance)
      expect(simulation.settlement.side).to eq(accepting)
    end
  end
end
