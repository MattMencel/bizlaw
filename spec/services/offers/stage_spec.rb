# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offers::Stage do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:day) { simulation.days.first }
  let(:organization) { simulation.section.organization }
  let(:dana) { a_user(organization: organization, name: "Dana", email: "dana@wiu.edu") }
  let(:ravi) { a_user(organization: organization, name: "Ravi", email: "ravi@wiu.edu") }

  def term(key) = simulation.case_version.terms.find_by!(key: key)

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

  # The Second is defined against the member who staged the Offer, so a
  # revision leaves that Attribution where it is. Reassigning it would erase
  # the one member the gate exists to exclude — and take them out of the Team,
  # since there is no roster and members are folded from Attribution.
  it "leaves the staging attributed to whoever put the Offer on the table" do
    stage(by: dana)
    revised = stage(by: ravi, terms: {"money" => 40_000_00})

    expect(revised.staged_by).to eq(dana)
    expect(side.members).to include(dana)
    expect(revised.eligible_seconders).not_to include(dana)
  end

  it "carries a note for the Instructor to read" do
    expect(stage(note: "We think they will take this before discovery.").note)
      .to eq("We think they will take this before discovery.")
  end

  it "refuses a Term the Case does not author" do
    expect { stage(terms: {"a_pony" => nil}) }
      .to raise_error(ArgumentError, /a_pony is not on this Case's Terms vocabulary/)
  end

  # The Terms arrive as a Hash and cannot be doubled; the Exhibits arrive as a
  # list and can. Without the seam saying so, a doubled control press comes back
  # as the unique index's fault rather than as a refusal.
  it "refuses an Exhibit named twice on one Offer" do
    simulation = a_simulation
    riding = simulation.plaintiff_side.case_file_documents.create!(
      day: simulation.days.first,
      case_document: simulation.case_version.documents.find_by!(identifier: "personnel_file")
    )

    expect {
      Offers::Stage.call(
        side: simulation.plaintiff_side, day: simulation.days.first,
        by: a_user(organization: simulation.section.organization, name: "Ada", email: "a@wiu.edu"),
        terms: {"money" => 1_000_00}, exhibits: [riding, riding]
      )
    }.to raise_error(ArgumentError, /rides an Offer once/)
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

  # `Day#open?` is only `closed_at IS NULL`, so every unplayed Day passes it.
  # A draft left waiting there is checked for playability only when it is
  # drawn, and an Exhibit it carries can be spent on the Day before — so the
  # draft reaches its own Day holding a card that is already gone.
  it "refuses a draft on a Day that has not opened yet" do
    expect {
      described_class.call(side: side, day: simulation.days.find_by!(ordinal: 2),
        by: dana, terms: {"money" => 45_000_00})
    }.to raise_error(Offers::DayNotOpen)
    expect(side.staged_offers).to be_empty
  end

  # The other end of `an_offer_has_already_been_committed_today`. A Team commits
  # at most one Offer a Day, so a Day whose Offer is executed has no second
  # position to put on the table — and the Day stays open until the other Side
  # commits, so the window is real. What it protects is the executed instrument:
  # `TermsBoard#ours` prefers the draft to the committed Offer, so a revision
  # landing here would print terms over two countersignatures that never signed
  # them.
  describe "a Day this Team has already executed its Offer on" do
    before do
      stage
      Days::Command.apply(
        act: :commit_offer, side: side, day: day, by: dana, seconded_by: seconder
      )
    end

    # `Side#members` folds from Attribution, so a teammate who has done nothing
    # cannot second anything.
    let(:seconder) do
      Days::Command.apply(act: :spend, side: side, day: day, by: ravi,
        kind: CaseAction::CONSULT_CLIENT)
      ravi
    end

    it "refuses a fresh position" do
      expect { stage(terms: {"apology" => nil}) }.to raise_error(Offers::AlreadyCommitted)
    end

    # The service refuses it against a read taken before the transaction; the
    # triggers are the rule where a commit landing inside that window cannot get
    # past it. A revision touches no `staged_offers` row an INSERT trigger would
    # see, so the Terms carry the rule too.
    it "refuses one underneath the model too" do
      expect {
        StagedOffer.create!(side: side, day: day, staged_by: ravi)
      }.to raise_error(ActiveRecord::StatementInvalid, /staged_offers_need_an_unexecuted_day/)
    end

    it "refuses a revision underneath the model too" do
      offer = side.staged_offer_on(day)

      expect {
        offer.offer_terms.create!(case_term: term("apology"), amount_cents: nil)
      }.to raise_error(
        ActiveRecord::StatementInvalid, /staged_offer_terms_need_an_unexecuted_day/
      )
    end

    # The race the trigger exists for: the commit lands between this seam's read
    # and its write. What a caller gets is this seam's own refusal rather than a
    # database fault, the way `Days::Command` turns its raced ceilings back into
    # quotes — a student is owed the sentence, not a 500.
    it "reads a commit that lands inside its own window as the same refusal" do
      allow(side).to receive(:committed_offer_on).with(day).and_return(nil)

      expect { stage(terms: {"apology" => nil}) }.to raise_error(Offers::AlreadyCommitted)
    end

    it "leaves the draft the commit was copied from exactly as it was" do
      expect {
        begin
          stage(terms: {"apology" => nil})
        rescue Offers::AlreadyCommitted
          nil
        end
      }.not_to change { side.staged_offer_on(day).terms.map(&:key) }
    end

    # The Day is still open. It closes on the second Side's commitment, and the
    # other Side has not filed.
    it "refuses it while the Day is still open" do
      expect { stage(terms: {"apology" => nil}) }.to raise_error(Offers::AlreadyCommitted)
      expect(day.reload).not_to be_closed
    end
  end

  # The same race on the other rule, and the same answer. The other Side closes
  # the Day by committing it, so a draft in flight when that happens is the
  # ordinary two-tab case rather than a fault.
  describe "a Day that closes inside the staging window" do
    it "reads it as the Day having closed rather than as a fault" do
      stage
      Days::Close.call(day)
      allow(day).to receive(:closed?).and_return(false)

      expect { stage(terms: {"apology" => nil}) }.to raise_error(Offers::DayClosed)
    end
  end

  # The service refuses it against a Day it holds in memory; the trigger is the
  # rule where a stale object cannot get past it.
  it "refuses one underneath the model too" do
    Days::Close.call(day)

    expect {
      StagedOffer.create!(side: side, day: day, staged_by: dana)
    }.to raise_error(ActiveRecord::StatementInvalid, /staged_offers_need_an_unclosed_day/)
  end

  # A revision touches no `staged_offers` row that an INSERT trigger would see,
  # so the Terms carry the rule too — otherwise the Day the service read as open
  # could close between that read and this write.
  it "refuses a revision underneath the model once the Day has closed" do
    offer = stage
    Days::Close.call(day)

    expect {
      offer.offer_terms.create!(case_term: side.case_version.terms.find_by!(key: "nda"))
    }.to raise_error(ActiveRecord::StatementInvalid, /staged_offer_terms_need_an_unclosed_day/)
  end

  # Nothing writes a Term this way today — a revision deletes and rewrites them
  # — but the rule is in the database so that an insert path added later cannot
  # move a position on a Day that has ended.
  it "refuses a Term moved in place once the Day has closed" do
    term = stage.offer_terms.sole
    Days::Close.call(day)

    expect { term.update!(amount_cents: 1_000_00) }
      .to raise_error(ActiveRecord::StatementInvalid, /staged_offer_terms_stay_on_an_unclosed_day/)
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
