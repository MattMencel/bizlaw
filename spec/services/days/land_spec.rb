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

  describe "an Action bought on an earlier Day" do
    it "fills the Case File when its landing Day opens" do
      spend(CaseAction::DEPOSE_WITNESS, side: defendant, on: simulation.days.first)

      open_day(2)
      expect(case_file(defendant)).to be_empty

      open_day(3)
      expect(case_file(defendant)).to eq(["deposition_of_the_supervisor"])
    end

    it "fills only the Case File of the Side that bought it" do
      spend(CaseAction::DEPOSE_WITNESS, side: defendant, on: simulation.days.first)
      open_day(2)
      open_day(3)

      expect(case_file(plaintiff)).to be_empty
    end

    it "yields every document the Action authors and nothing another Action hides" do
      spend(CaseAction::REQUEST_DOCUMENTS, side: plaintiff, on: simulation.days.first)

      open_day(2)

      expect(case_file(plaintiff)).to eq(["personnel_file"])
    end
  end

  # A lead time of zero lands the result on the Day it was bought, and that
  # Day's open has already happened.
  it "lands an Action with no lead time on the Day it was bought" do
    version = simulation.case_version
    version.actions.find_by!(kind: CaseAction::RESEARCH_PRECEDENT).update!(lead_time_days: 0)

    spend(CaseAction::RESEARCH_PRECEDENT, side: plaintiff, on: simulation.days.first)

    expect(case_file(plaintiff)).to eq(["memorandum_on_comparable_awards"])
  end

  describe "a document that carries no Exhibit" do
    it "is filed and is visibly not playable" do
      spend(CaseAction::RESEARCH_PRECEDENT, side: plaintiff, on: simulation.days.first)
      open_day(2)

      filed = plaintiff.case_file_documents.sole
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

      filed = defendant.case_file_documents.sole
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
      expect(plaintiff.case_file_documents.sole).not_to be_playable
    end

    it "lands on the finder's own Client at discovery" do
      expect(plaintiff.bound_consumed).to eq(0.25)
      expect(simulation.defendant_side.bound_consumed).to be_zero
    end

    it "appends one shift row against the finder's own Client's bound" do
      shift = plaintiff.client_shifts.sole

      expect(shift.source_kind).to eq(ClientShift::UNFAVORABLE_DISCOVERY)
      expect(shift.source_ref).to eq(plaintiff.case_file_documents.sole.id)
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

      expect { open_day(3) }.not_to change(plaintiff.case_file_documents, :count)
      expect(plaintiff.client_shifts.count).to eq(1)
      expect(plaintiff.bound_consumed).to eq(0.25)
    end

    it "keeps the Day the document was first filed on" do
      spend(CaseAction::DEPOSE_WITNESS, side: plaintiff, on: simulation.days.first)
      open_day(2)
      open_day(3)
      open_day(4)
      open_day(3)

      expect(plaintiff.case_file_documents.sole.day.ordinal).to eq(3)
    end
  end

  it "files a document once when the same Action is bought on two Days" do
    spend(CaseAction::REQUEST_DOCUMENTS, side: plaintiff, on: simulation.days.first)
    open_day(2)
    spend(CaseAction::REQUEST_DOCUMENTS, side: plaintiff, on: simulation.days.second)
    open_day(3)

    expect(plaintiff.case_file_documents.count).to eq(1)
    expect(plaintiff.docket_entries.count).to eq(2)
  end
end
