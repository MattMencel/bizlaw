# frozen_string_literal: true

require "rails_helper"

RSpec.describe Days::Land do
  let(:simulation) { a_simulation }
  let(:plaintiff) { simulation.plaintiff_side }
  let(:defendant) { simulation.defendant_side }
  let(:student) { a_user(organization: simulation.section.organization) }

  def spend(kind, side:, on:)
    Days::Command.apply(act: :spend, side: side, day: on, by: student, kind: kind)
  end

  def open_day(ordinal)
    Days::Open.call(simulation.days.find_by!(ordinal: ordinal))
  end

  def case_file(side)
    side.case_file_documents.reload.map { |filed| filed.case_document.identifier }
  end

  # What preparation yielded, as opposed to what the Team walked in with. Every
  # Case File holds the open hand from Day 1, so an example about landing says
  # which half of the file it is about rather than asserting over both.
  def discovered(side)
    discoveries(side).map { |filed| filed.case_document.identifier }
  end

  def the_discovery(side) = discoveries(side).sole

  def discoveries(side)
    side.case_file_documents.reload.reject { |filed| filed.case_document.in_hand_at_the_open? }
  end

  # Provenance's two authored hands. They wait behind no Action, so they arrive
  # on Day 1 — the Day the Team came to know them — and on Day 1 they are the
  # whole of what a Case File holds.
  describe "the documents a Team walks in with" do
    it "fills both Case Files on Day 1, before anything has been spent" do
      expect(case_file(plaintiff))
        .to contain_exactly("the_termination_letter", "the_claimants_own_notes")
      expect(case_file(defendant)).to eq(["the_termination_letter"])
    end

    it "files them on Day 1 whichever Day is being opened" do
      open_day(2)

      expect(plaintiff.case_file_documents.map { |filed| filed.day.ordinal }).to all(eq(1))
    end

    it "leaves them found rather than served, and carrying no Exhibit to play" do
      filed = plaintiff.case_file_documents.reload

      expect(filed.map(&:served?)).to all(be(false))
      expect(filed.map(&:playable?)).to all(be(false))
    end

    # Nothing here can move a Client before the first Day is played: an
    # unfavorable Exhibit in a hand at the open is refused at authoring.
    it "moves neither Client" do
      expect(plaintiff.bound_consumed).to be_zero
      expect(defendant.bound_consumed).to be_zero
    end

    it "deals the hand once when Day 1 is opened again" do
      expect { open_day(1) }.not_to change { plaintiff.case_file_documents.reload.count }
    end

    # `Days::Command` calls this seam for a lead time of zero, on a Day 1 whose
    # hand has already been dealt.
    it "deals the hand once when a spend lands on Day 1" do
      simulation.case_version.actions
        .find_by!(kind: CaseAction::RESEARCH_PRECEDENT).update!(lead_time_days: 0)

      spend(CaseAction::RESEARCH_PRECEDENT, side: plaintiff, on: simulation.days.first)

      expect(case_file(plaintiff)).to contain_exactly(
        "the_termination_letter", "the_claimants_own_notes", "memorandum_on_comparable_awards"
      )
    end
  end

  describe "an Action bought on an earlier Day" do
    it "fills the Case File when its landing Day opens" do
      spend(CaseAction::DEPOSE_WITNESS, side: defendant, on: simulation.days.first)

      open_day(2)
      expect(discovered(defendant)).to be_empty

      open_day(3)
      expect(discovered(defendant)).to eq(["deposition_of_the_supervisor"])
    end

    it "fills only the Case File of the Side that bought it" do
      spend(CaseAction::DEPOSE_WITNESS, side: defendant, on: simulation.days.first)
      open_day(2)
      open_day(3)

      expect(discovered(plaintiff)).to be_empty
    end

    it "yields every document the Action authors and nothing another Action hides" do
      spend(CaseAction::REQUEST_DOCUMENTS, side: plaintiff, on: simulation.days.first)

      open_day(2)

      expect(discovered(plaintiff)).to eq(["personnel_file"])
    end
  end

  # A lead time of zero lands the result on the Day it was bought, and that
  # Day's open has already happened.
  it "lands an Action with no lead time on the Day it was bought" do
    version = simulation.case_version
    version.actions.find_by!(kind: CaseAction::RESEARCH_PRECEDENT).update!(lead_time_days: 0)

    spend(CaseAction::RESEARCH_PRECEDENT, side: plaintiff, on: simulation.days.first)

    expect(discovered(plaintiff)).to eq(["memorandum_on_comparable_awards"])
  end

  describe "a document that carries no Exhibit" do
    it "is filed and is visibly not playable" do
      spend(CaseAction::RESEARCH_PRECEDENT, side: plaintiff, on: simulation.days.first)
      open_day(2)

      filed = the_discovery(plaintiff)
      expect(filed).not_to be_exhibit
      expect(filed).not_to be_playable
      expect(plaintiff.bound_consumed).to be_zero
    end
  end

  describe "a favorable Exhibit" do
    it "is held and playable, and moves nobody at discovery" do
      spend(CaseAction::DEPOSE_WITNESS, side: defendant, on: simulation.days.first)
      open_day(2)
      open_day(3)

      filed = the_discovery(defendant)
      expect(filed).to be_playable
      expect(defendant.bound_consumed).to be_zero
      expect(plaintiff.bound_consumed).to be_zero
    end
  end

  describe "an unfavorable Exhibit" do
    before do
      spend(CaseAction::DEPOSE_WITNESS, side: plaintiff, on: simulation.days.first)
      open_day(2)
      open_day(3)
    end

    it "is filed and is not playable at all" do
      expect(the_discovery(plaintiff)).not_to be_playable
    end

    it "lands on the finder's own Client at discovery" do
      expect(plaintiff.bound_consumed).to eq(0.25)
      expect(simulation.defendant_side.bound_consumed).to be_zero
    end

    it "appends one shift row against the finder's own Client's bound" do
      shift = plaintiff.client_shifts.sole

      expect(shift.source_kind).to eq(ClientShift::UNFAVORABLE_DISCOVERY)
      expect(shift.source_ref).to eq(the_discovery(plaintiff).id)
      expect(shift.day.ordinal).to eq(3)
      expect(shift.requested_fraction).to eq(0.25)
      expect(shift.applied_fraction).to eq(0.25)
    end
  end

  # The unique index is what makes this harmless, rather than an ordering the
  # callers have to get right.
  describe "the same Day opened twice" do
    it "files the document once and moves the bound once" do
      spend(CaseAction::DEPOSE_WITNESS, side: plaintiff, on: simulation.days.first)
      open_day(2)
      open_day(3)

      expect { open_day(3) }.not_to change { discoveries(plaintiff).count }
      expect(plaintiff.client_shifts.count).to eq(1)
      expect(plaintiff.bound_consumed).to eq(0.25)
    end

    it "keeps the Day the document was first filed on" do
      spend(CaseAction::DEPOSE_WITNESS, side: plaintiff, on: simulation.days.first)
      open_day(2)
      open_day(3)
      open_day(4)
      open_day(3)

      expect(the_discovery(plaintiff).day.ordinal).to eq(3)
    end
  end

  # The total consumed is the same whichever lands first, but an unordered
  # association would record an arbitrary split between the two rows.
  describe "two unfavorable discoveries that cannot both fit the bound" do
    before do
      version = simulation.case_version
      action = version.actions.find_by!(kind: CaseAction::MANAGE_PRESS)
      [["a_hostile_column", 0.8], ["a_second_hostile_column", 0.5]].each do |identifier, shift|
        version.documents.create!(
          case_action: action, provenance: CaseDocument::DISCOVERABLE,
          identifier: identifier, title: identifier, body: "Prose.",
          exhibit_target_role: Side::PLAINTIFF, exhibit_shift_fraction: shift
        )
      end
    end

    it "clips the second against what the first left, in authored order" do
      spend(CaseAction::MANAGE_PRESS, side: plaintiff, on: simulation.days.first)
      open_day(2)

      expect(plaintiff.client_shifts.order(:source_ref).map(&:requested_fraction))
        .to eq([0.8, 0.5])
      expect(plaintiff.client_shifts.order(:source_ref).map(&:applied_fraction))
        .to eq([0.8, 0.2])
      expect(plaintiff.bound_consumed).to eq(1)
    end
  end

  it "files a document once when the same Action is bought on two Days" do
    spend(CaseAction::REQUEST_DOCUMENTS, side: plaintiff, on: simulation.days.first)
    open_day(2)
    spend(CaseAction::REQUEST_DOCUMENTS, side: plaintiff, on: simulation.days.second)
    open_day(3)

    expect(discoveries(plaintiff).count).to eq(1)
    expect(plaintiff.docket_entries.count).to eq(2)
  end
end
