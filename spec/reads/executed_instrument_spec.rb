# frozen_string_literal: true

require "rails_helper"

# The settlement beat. Nothing is written for it: it is the accepted Offer's own
# term sheet with both countersignature lines filled and an execution stamp,
# read off `committed_offers`, `committed_offer_terms` and `offer_acceptances`.
#
# Both Sides read one, on the one shared instrument. Only the Client's beat
# differs between them, and it carries no Reaction Band.
RSpec.describe ExecutedInstrument do
  let(:simulation) { a_simulation }
  let(:offering) { simulation.plaintiff_side }
  let(:accepting) { simulation.defendant_side }
  let(:day) { simulation.days.first }
  let(:organization) { simulation.section.organization }
  let(:dana) { a_user(organization: organization, name: "Dana", email: "dana@wiu.edu") }
  let(:ravi) { a_user(organization: organization, name: "Ravi", email: "ravi@wiu.edu") }
  let(:kofi) { a_user(organization: organization, name: "Kofi", email: "kofi@wiu.edu") }
  let(:noor) { a_user(organization: organization, name: "Noor", email: "noor@wiu.edu") }
  let(:instructor) do
    a_user(organization: organization, name: "Professor Adeyemi", email: "adeyemi@wiu.edu")
  end

  # There is no roster yet, so a member joins a Team by acting for it.
  def a_member_of(side, person)
    Days::Command.apply(
      act: :spend, side: side, day: day, by: person, kind: CaseAction::CONSULT_CLIENT
    )
    person
  end

  def an_offer_on_the_table(terms: {"money" => 45_000_00, "apology" => nil})
    a_member_of(offering, ravi)
    Offers::Stage.call(side: offering, day: day, by: dana, terms: terms)
    Days::Command.apply(
      act: :commit_offer, side: offering, day: day, by: dana, seconded_by: ravi
    )
  end

  def a_settlement(seconded_by: noor)
    offer = an_offer_on_the_table
    a_member_of(accepting, noor)
    Offers::Accept.call(
      offer: offer, side: accepting, day: day, by: kofi, seconded_by: seconded_by
    )
  end

  def instrument(side) = described_class.for(side)

  describe "a run that has not settled" do
    it "has no instrument, and reads as one rather than raising" do
      an_offer_on_the_table

      read = instrument(offering)
      expect(read).not_to be_executed
      expect(read.terms).to be_empty
      expect(read.offered_by).to be_nil
      expect(read.accepted_by).to be_nil
      expect(read.executed_at).to be_nil
      expect(read.beat).to be_nil
    end
  end

  describe "the term sheet" do
    it "is the accepted Offer's Terms, in the Case's authored order" do
      a_settlement

      expect(instrument(offering).terms.map { |term| [term.key, term.amount_cents] })
        .to eq([["money", 45_000_00], ["apology", nil]])
    end

    # A settlement including an apology includes an apology. Nothing is put in
    # the slot that carries no figure.
    it "keeps the Terms that carry no figure distinct from the one that does" do
      a_settlement
      money, apology = instrument(offering).terms

      expect(money).to be_money
      expect(apology).not_to be_money
    end

    it "is the same sheet on both Sides of the table" do
      a_settlement

      expect(instrument(accepting).terms).to eq(instrument(offering).terms)
    end
  end

  describe "the countersignatures" do
    it "names the Side that put the paper on the table and who signed it" do
      a_settlement
      line = instrument(offering).offered_by

      expect(line.side_role).to eq(Side::PLAINTIFF)
      expect(line.signed_by).to eq(dana)
      expect(line.seconded_by).to eq(ravi)
      expect(line).not_to be_under_waiver
    end

    # An Acceptance *is* a countersignature, which is why the beat is the
    # instrument executed rather than a second document about it.
    it "names the Side that took it and who signed for them" do
      a_settlement
      line = instrument(offering).accepted_by

      expect(line.side_role).to eq(Side::DEFENDANT)
      expect(line.signed_by).to eq(kofi)
      expect(line.seconded_by).to eq(noor)
    end

    # The Instructor never Seconds on a Team's behalf, so a line that landed
    # under a waiver carries no seconder at all rather than naming them.
    it "shows an Acceptance under an Instructor's waiver as a line with no Second" do
      Offers::WaiveSecond.call(side: accepting, day: day, by: instructor)
      a_settlement(seconded_by: nil)
      line = instrument(accepting).accepted_by

      expect(line.signed_by).to eq(kofi)
      expect(line).to be_under_waiver
    end
  end

  describe "the execution stamp" do
    it "is when it was taken, and the Day it was taken on" do
      acceptance = a_settlement
      read = instrument(accepting)

      expect(read.executed_at).to eq(acceptance.created_at)
      expect(read.executed_on).to eq(day)
    end
  end

  describe "the Client's beat" do
    it "reads from this Team's own Client, and says they took it" do
      a_settlement
      beat = instrument(accepting).beat

      expect(instrument(accepting).acceptance_role).to eq(CaseClient::TOOK_IT)
      expect(beat.client_role).to eq(Side::DEFENDANT)
      expect(beat.line).to eq(accepting.client.settlement_line(CaseClient::TOOK_IT))
    end

    it "tells the Team whose Offer was taken that it was theirs that went" do
      a_settlement
      beat = instrument(offering).beat

      expect(instrument(offering).acceptance_role).to eq(CaseClient::HAD_IT_TAKEN)
      expect(beat.client_role).to eq(Side::PLAINTIFF)
      expect(beat.line).to eq(offering.client.settlement_line(CaseClient::HAD_IT_TAKEN))
    end

    it "gives the two Teams different words over identical terms" do
      a_settlement

      expect(instrument(accepting).beat.line).not_to eq(instrument(offering).beat.line)
    end

    # The face is authored to the occasion rather than derived from a band, and
    # is invariant: one that fell at a bad deal would be a free Settlement
    # Quality read arriving through the art.
    it "carries the one settlement expression, whichever Side is reading" do
      a_settlement

      expect(instrument(offering).beat.expression).to eq(described_class::EXPRESSION)
      expect(instrument(accepting).beat.expression).to eq(described_class::EXPRESSION)
    end
  end

  it "is what a Side hands back for it" do
    a_settlement

    expect(offering.executed_instrument).to be_executed
  end
end
