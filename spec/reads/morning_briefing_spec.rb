# frozen_string_literal: true

require "rails_helper"

# What a Day opens with. Composed on read from objects the Case already authors,
# so a briefing is never authored per Case and never written down — see ADR
# 0004. The same object serves a returning absent teammate, widened.
RSpec.describe MorningBriefing do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:opponent) { simulation.defendant_side }
  let(:organization) { simulation.section.organization }
  let(:dana) { a_user(organization: organization) }
  let(:priya) do
    a_user(organization: organization, name: "Priya Raman", email: "priya@example.edu")
  end

  def briefing(on:, since: nil) = described_class.for(side, day: on, since: since)

  def spend(kind, on:, by: side, member: dana)
    Days::Command.apply(act: :spend, side: by, day: on, by: member, kind: kind)
  end

  def open_day(ordinal) = Days::Open.call(simulation.days.find_by!(ordinal: ordinal))

  def day(ordinal) = simulation.days.find_by!(ordinal: ordinal)

  describe "Day 1" do
    let(:read) { briefing(on: day(1)) }

    it "has only the what-you-start-with section populated" do
      expect(read.landed).to be_empty
      expect(read.served).to be_empty
      expect(read.what_you_start_with.map(&:title))
        .to contain_exactly("The termination letter", "The claimant's own notes")
    end

    it "carries the Client's opening statement, authored rather than generated" do
      expect(read.opening_statement).to include("Eleven years, and they walked me out")
    end

    it "carries the whole calendar, so a lead time can be planned against it" do
      expect(read.calendar.map(&:ordinal)).to eq((1..10).to_a)
      expect(read.calendar.first.in_fiction_date).to eq(Date.new(2026, 3, 2))
    end

    it "carries the published Rubric, dimensions and weights only" do
      expect(read.rubric.dimensions).to include(/Settlement quality/, /Collaboration/)
      expect(read.rubric.bonus).to include("Creative terms")
    end

    # A room is never empty, so no room's own state can carry it.
    it "names the two-room grammar in one line of fixed copy" do
      expect(read.two_room_line).to include("Firm", "Boardroom", "both Sides")
    end

    it "covers one Day" do
      expect(read.days.to_a).to eq([1])
    end
  end

  describe "an ordinary later morning" do
    before do
      spend(CaseAction::DEPOSE_WITNESS, on: day(1))
      open_day(2)
      open_day(3)
    end

    it "carries what the Team's Actions have just landed" do
      expect(briefing(on: day(3)).landed.map(&:title))
        .to eq(["Deposition of the plant supervisor"])
    end

    # What a Team walked in with is not news on Day 3, but it is still what the
    # Team started with — so it stays in its own section rather than reappearing.
    it "keeps what the Team walked in with out of what just landed" do
      read = briefing(on: day(3))

      expect(read.landed.map(&:title)).not_to include("The termination letter")
      expect(read.what_you_start_with.map(&:title)).to include("The termination letter")
    end

    it "says nothing landed on a Day nothing landed on" do
      expect(briefing(on: day(2)).landed).to be_empty
    end
  end

  describe "after the other Side served an Exhibit" do
    before do
      spend(CaseAction::DEPOSE_WITNESS, on: day(1), by: opponent)
      open_day(2)
      open_day(3)
      spend(CaseAction::CONSULT_CLIENT, on: day(3), by: opponent, member: priya)
      offer = Offers::Stage.call(side: opponent, day: day(3), by: dana,
        terms: {CaseTerm::MONEY => 45_000_00})
      offer.offer_exhibits.create!(
        case_file_document: opponent.case_file_documents
          .find { |filed| filed.title == "Deposition of the plant supervisor" }
      )
      Days::Command.apply(act: :commit_offer, side: opponent, day: day(3), by: dana,
        seconded_by: priya)
    end

    it "carries the document the other Side served" do
      expect(briefing(on: day(3)).served.map(&:title))
        .to eq(["Deposition of the plant supervisor"])
    end

    # The receiving Team is served the document and never its effect.
    it "hands over the document and nothing that could be played back" do
      served = briefing(on: day(3)).served.sole

      expect(served.playable).to be(false)
      expect(served).to be_served
    end

    it "keeps a served document out of what the Team's own Actions landed" do
      expect(briefing(on: day(3)).landed).to be_empty
    end
  end

  # The same object, widened. There is no per-student progress state anywhere in
  # the design, so which Days a teammate missed is the caller's to say.
  describe "a returning absent teammate" do
    before do
      spend(CaseAction::REQUEST_DOCUMENTS, on: day(1))
      open_day(2)
      spend(CaseAction::DEPOSE_WITNESS, on: day(2))
      open_day(3)
      open_day(4)
    end

    it "is given the same object over the Days they missed" do
      read = briefing(on: day(4), since: day(2))

      expect(read.days.to_a).to eq([2, 3, 4])
      expect(read.landed.map(&:title)).to contain_exactly(
        "The claimant's personnel file", "Deposition of the plant supervisor"
      )
    end

    it "is caught up on what the Team started with, as every briefing is" do
      expect(briefing(on: day(4), since: day(2)).what_you_start_with.map(&:title))
        .to contain_exactly("The termination letter", "The claimant's own notes")
    end

    it "leaves the ordinary morning narrow, covering its own Day alone" do
      read = briefing(on: day(4))

      expect(read.days.to_a).to eq([4])
      expect(read.landed.map(&:title)).to eq(["Deposition of the plant supervisor"])
    end
  end

  it "writes nothing" do
    first = day(1)

    expect { briefing(on: first).landed }.not_to change(CaseFileDocument, :count)
  end
end
