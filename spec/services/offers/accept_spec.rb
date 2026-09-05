# frozen_string_literal: true

require "rails_helper"

# The other Side takes the deal, and its own Team gates it exactly as the commit
# was gated: an Offer and an Acceptance are the only two acts inside a Team that
# need a Second.
RSpec.describe Offers::Accept do
  let(:simulation) { a_simulation }
  let(:offering) { simulation.plaintiff_side }
  let(:accepting) { simulation.defendant_side }
  let(:day) { simulation.days.first }
  let(:following) { simulation.days.second }
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

  # An Offer on the plaintiff's table, committed and standing.
  def an_offer_on_the_table
    a_member_of(offering, ravi)
    Offers::Stage.call(side: offering, day: day, by: dana, terms: {"money" => 45_000_00})
    Days::Command.apply(
      act: :commit_offer, side: offering, day: day, by: dana, seconded_by: ravi
    )
  end

  def accept(offer, side: accepting, on: day, by: kofi, seconded_by: nil)
    described_class.call(offer: offer, side: side, day: on, by: by, seconded_by: seconded_by)
  end

  it "records the Acceptance against the Team that took it, naming both members" do
    offer = an_offer_on_the_table
    a_member_of(accepting, noor)

    acceptance = accept(offer, by: kofi, seconded_by: noor)

    expect(acceptance.committed_offer).to eq(offer)
    expect(acceptance.side).to eq(accepting)
    expect(acceptance.day).to eq(day)
    expect(acceptance.accepted_by).to eq(kofi)
    expect(acceptance.seconded_by).to eq(noor)
    expect(offer.reload).to be_accepted
  end

  it "costs nothing" do
    offer = an_offer_on_the_table
    a_member_of(accepting, noor)
    budget = accepting.budget_on(day)
    before = DayBudget::HALVES.index_with { |half| budget.remaining_in(half) }

    accept(offer, by: kofi, seconded_by: noor)

    expect(DayBudget::HALVES.index_with { |half| budget.reload.remaining_in(half) }).to eq(before)
  end

  it "is on the accepting Team's Docket as an act without a cost" do
    offer = an_offer_on_the_table
    a_member_of(accepting, noor)

    accept(offer, by: kofi, seconded_by: noor)

    entry = accepting.docket.last
    expect(entry.act).to eq(Docket::OFFER_ACCEPTED)
    expect(entry.by).to eq(kofi)
    expect(entry.cost).to be_nil
  end

  # An Offer stands on the table until it is taken. The Day it is taken on need
  # not be the Day it was committed on.
  it "can be taken on a later Day" do
    offer = an_offer_on_the_table
    a_member_of(accepting, noor)
    Days::Commit.call(side: offering, day: day, by: dana)
    Days::Commit.call(side: accepting, day: day, by: kofi)

    acceptance = accept(offer, on: following, by: kofi, seconded_by: noor)

    expect(acceptance.day).to eq(following)
  end

  describe "the gate" do
    it "refuses the member who accepted it seconding themselves" do
      offer = an_offer_on_the_table
      a_member_of(accepting, kofi)

      expect { accept(offer, by: kofi, seconded_by: kofi) }
        .to raise_error(Offers::NotSeconded)
    end

    it "refuses a Team whose other members are absent" do
      offer = an_offer_on_the_table

      expect { accept(offer, by: kofi, seconded_by: nil) }.to raise_error(Offers::NotSeconded)
      expect(OfferAcceptance.count).to eq(0)
    end

    # The Second is the accepting Team's own. A member of the Team across the
    # table cannot pass it.
    it "refuses a Second from the other Side" do
      offer = an_offer_on_the_table

      expect { accept(offer, by: kofi, seconded_by: ravi) }.to raise_error(Offers::NotSeconded)
    end

    it "admits an Acceptance under an Instructor's waiver, naming nobody as its Second" do
      offer = an_offer_on_the_table
      Offers::WaiveSecond.call(side: accepting, day: day, by: instructor)

      acceptance = accept(offer, by: kofi, seconded_by: nil)

      expect(acceptance).not_to be_seconded
      expect(acceptance.accepted_by).to eq(kofi)
    end
  end

  # Two teammates pressing the same control is the ordinary case, so the second
  # press keeps the Attribution of whoever actually took it first.
  it "takes an Offer once" do
    offer = an_offer_on_the_table
    a_member_of(accepting, noor)
    first = accept(offer, by: kofi, seconded_by: noor)

    again = accept(offer, by: noor, seconded_by: kofi)

    expect(again.id).to eq(first.id)
    expect(again.accepted_by).to eq(kofi)
    expect(OfferAcceptance.count).to eq(1)
  end

  it "refuses a Side accepting the Offer it put on the table" do
    offer = an_offer_on_the_table

    expect { accept(offer, side: offering, by: ravi, seconded_by: dana) }
      .to raise_error(ArgumentError, /cannot accept the Offer it put on the table/)
  end

  it "refuses a Day the Instructor has already ended" do
    offer = an_offer_on_the_table
    a_member_of(accepting, noor)
    Days::Close.call(day)

    expect { accept(offer, by: kofi, seconded_by: noor) }.to raise_error(Offers::DayClosed)
  end
end
