# frozen_string_literal: true

require "rails_helper"

# What a Team knows, as against the Docket's what it has done.
RSpec.describe CaseFile do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:opponent) { simulation.defendant_side }
  let(:student) { a_user(organization: simulation.section.organization) }

  def spend(kind, on:, by: side)
    Days::Command.apply(act: :spend, side: by, day: on, by: student, kind: kind)
  end

  def open_day(ordinal) = Days::Open.call(simulation.days.find_by!(ordinal: ordinal))

  def titles(of: side) = described_class.for(of).entries.map(&:title)

  it "opens holding what the Team walked in with, flagged as found" do
    expect(titles).to contain_exactly("The termination letter", "The claimant's own notes")
    expect(described_class.for(side).entries.map(&:at_the_open?)).to all(be(true))
    expect(described_class.for(side).entries.map(&:found?)).to all(be(true))
  end

  it "fills with what an Action yielded on the Day it landed" do
    spend(CaseAction::REQUEST_DOCUMENTS, on: simulation.days.first)
    open_day(2)

    expect(titles).to include("The claimant's personnel file")
  end

  it "reads in the order the documents arrived" do
    spend(CaseAction::REQUEST_DOCUMENTS, on: simulation.days.first)
    open_day(2)

    expect(titles.last).to eq("The claimant's personnel file")
  end

  # An Action with no lead time lands on Day 1 too, so the Day cannot say which
  # documents a Team walked in with. Provenance can.
  it "does not call a same-Day discovery something the Team started with" do
    simulation.case_version.actions
      .find_by!(kind: CaseAction::RESEARCH_PRECEDENT).update!(lead_time_days: 0)
    spend(CaseAction::RESEARCH_PRECEDENT, on: simulation.days.first)

    memorandum = described_class.for(side).entries
      .find { |entry| entry.title == "Memorandum on comparable awards" }

    expect(memorandum.day.ordinal).to eq(1)
    expect(memorandum).not_to be_at_the_open
  end

  describe "the empty state, which is the tutorial" do
    # Nothing in the reference Case leaves a Case File empty, because every Team
    # walks in holding something. A Case authoring no open hand is what an empty
    # one looks like, and the sentence is what it says instead of nothing.
    let(:empty_handed) do
      version = a_case_version(version: "2.0.0")
      version.documents.in_hand_at_the_open.destroy_all
      Simulations::Create.call(section: a_section, case_version: version).plaintiff_side
    end

    it "describes what a Case File would hold" do
      read = described_class.for(empty_handed)

      expect(read).to be_empty
      expect(read.empty_state).to include("what your Team knows")
    end

    it "says nothing once there is something to read" do
      expect(described_class.for(side).empty_state).to be_nil
    end
  end

  describe "the Exhibit affordances" do
    it "are unavailable while nothing the Team holds carries one" do
      expect(described_class.for(side)).not_to be_exhibits_available
    end

    it "become available the moment a playable Exhibit lands" do
      spend(CaseAction::REQUEST_DOCUMENTS, on: simulation.days.first)
      open_day(2)

      expect(described_class.for(side)).to be_exhibits_available
    end

    # Not playable at all, so a control for it would be inert — and the rule is
    # to gate a control only where it would otherwise be inert.
    it "stay unavailable on an unfavorable Exhibit the Team found" do
      spend(CaseAction::DEPOSE_WITNESS, on: simulation.days.first)
      open_day(2)
      open_day(3)

      expect(titles).to include("Deposition of the plant supervisor")
      expect(described_class.for(side)).not_to be_exhibits_available
    end

    # Service gives a Team knowledge, never ammunition: a served document
    # carries no Exhibit property for its recipient.
    it "stay unavailable on a document the other Side served" do
      spend(CaseAction::DEPOSE_WITNESS, on: simulation.days.first, by: opponent)
      open_day(2)
      open_day(3)
      serve_the_deposition

      served = described_class.for(side).entries.find(&:served?)
      expect(served.title).to eq("Deposition of the plant supervisor")
      expect(served.playable).to be(false)
      expect(described_class.for(side)).not_to be_exhibits_available
    end

    # A Team that has spent its only Exhibit has still learned what the control
    # does. Taking the affordance away again would teach the opposite.
    it "stay available once the Team's only Exhibit is spent" do
      spend(CaseAction::DEPOSE_WITNESS, on: simulation.days.first, by: opponent)
      open_day(2)
      open_day(3)
      serve_the_deposition

      read = described_class.for(opponent)
      expect(read.entries.find(&:spent)).to be_present
      expect(read).to be_exhibits_available
    end
  end

  # The defendant plays the deposition at the plaintiff's Client, which serves
  # the document across the table and spends the Exhibit.
  def serve_the_deposition
    day = simulation.days.find_by!(ordinal: 3)
    teammate = a_user(organization: simulation.section.organization, name: "Priya Raman",
      email: "priya@example.edu")
    Days::Command.apply(act: :spend, side: opponent, day: day, by: teammate,
      kind: CaseAction::CONSULT_CLIENT)

    offer = Offers::Stage.call(side: opponent, day: day, by: student,
      terms: {CaseTerm::MONEY => 45_000_00})
    exhibit = opponent.case_file_documents
      .find { |filed| filed.title == "Deposition of the plant supervisor" }
    offer.offer_exhibits.create!(case_file_document: exhibit)

    Days::Command.apply(act: :commit_offer, side: opponent, day: day, by: student,
      seconded_by: teammate)
  end
end
