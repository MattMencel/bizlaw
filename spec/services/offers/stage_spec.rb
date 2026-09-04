# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offers::Stage do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:day) { simulation.days.first }
  let(:organization) { simulation.section.organization }
  let(:dana) { a_user(organization: organization, name: "Dana", email: "dana@wiu.edu") }
  let(:ravi) { a_user(organization: organization, name: "Ravi", email: "ravi@wiu.edu") }

  def stage(by: dana, terms: {"money" => 45_000_00}, note: nil)
    described_class.call(side: side, day: day, by: by, terms: terms, note: note)
  end

  it "puts a position on the table over the Case's authored vocabulary" do
    offer = stage(terms: {"money" => 45_000_00, "apology" => nil, "reinstatement" => nil})

    expect(offer.terms.map(&:key)).to contain_exactly("money", "apology", "reinstatement")
    expect(offer.amount_cents).to eq(45_000_00)
    expect(offer.staged_by).to eq(dana)
  end

  it "is visible to the whole Team rather than to the member who staged it" do
    stage

    expect(side.staged_offer_on(day)).to be_present
  end

  # Nothing has been spent, so there is nothing for the Budget to have moved and
  # nothing for the Docket's spend ledger to record.
  it "costs nothing" do
    budget = side.budget_on(day)
    before = DayBudget::HALVES.index_with { |half| budget.remaining_in(half) }

    stage
    stage(by: ravi, terms: {"money" => 40_000_00})
    stage(terms: {"money" => 38_000_00, "nda" => nil})

    expect(DayBudget::HALVES.index_with { |half| budget.reload.remaining_in(half) }).to eq(before)
    expect(side.docket_entries).to be_empty
  end

  it "replaces the position rather than amending it" do
    stage(terms: {"money" => 45_000_00, "apology" => nil})
    revised = stage(terms: {"money" => 40_000_00})

    expect(revised.terms.map(&:key)).to eq(["money"])
    expect(side.staged_offers.count).to eq(1)
  end

  # Whoever wrote the position now on the table is who the Second is measured
  # against, so a revision moves the Attribution with it.
  it "attributes a revision to the member who made it" do
    stage(by: dana)
    revised = stage(by: ravi, terms: {"money" => 40_000_00})

    expect(revised.staged_by).to eq(ravi)
  end

  it "carries a note for the Instructor to read" do
    expect(stage(note: "We think they will take this before discovery.").note)
      .to eq("We think they will take this before discovery.")
  end

  it "refuses a Term the Case does not author" do
    expect { stage(terms: {"a_pony" => nil}) }
      .to raise_error(ArgumentError, /a_pony is not on this Case's Terms vocabulary/)
  end

  it "refuses an Offer naming no Term at all" do
    expect { stage(terms: {}) }.to raise_error(ArgumentError, /at least one Term/)
  end

  it "refuses money without an amount" do
    expect { stage(terms: {"money" => nil}) }
      .to raise_error(ActiveRecord::RecordInvalid, /what an Offer of money is worth/)
  end

  it "refuses an amount on a Term that is not money" do
    expect { stage(terms: {"apology" => 1_000_00}) }
      .to raise_error(ActiveRecord::RecordInvalid, /belongs to money/)
  end

  it "refuses a draft on a Day that has already closed" do
    Days::Close.call(day)

    expect { stage }.to raise_error(Offers::DayClosed)
  end

  # The service refuses it against a Day it holds in memory; the trigger is the
  # rule where a stale object cannot get past it.
  it "refuses one underneath the model too" do
    Days::Close.call(day)

    expect {
      StagedOffer.create!(side: side, day: day, staged_by: dana)
    }.to raise_error(ActiveRecord::StatementInvalid, /staged_offers_need_an_unclosed_day/)
  end

  describe "the commit control a student is left holding" do
    it "names the teammates who may second it" do
      Days::Command.apply(
        act: :spend, side: side, day: day, by: ravi, kind: CaseAction::CONSULT_CLIENT
      )
      offer = stage(by: dana)

      expect(offer.eligible_seconders).to eq([ravi])
      expect(offer).to be_secondable
    end

    # A Team whose other members are absent stages an Offer it cannot commit.
    # The control is present and dead, which is what teaches the rule.
    it "names nobody where the Team's other members are absent" do
      offer = stage(by: dana)

      expect(offer.eligible_seconders).to be_empty
      expect(offer).not_to be_secondable
    end

    it "never names the member who wrote the position" do
      Days::Commit.call(side: side, day: simulation.days.second, by: ravi)
      offer = stage(by: ravi)

      expect(offer.eligible_seconders).not_to include(ravi)
    end
  end
end
