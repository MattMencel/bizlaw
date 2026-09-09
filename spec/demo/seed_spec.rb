# frozen_string_literal: true

require "rails_helper"

# The seed is the only way the game view gets developed at all, so what is
# under test here is the Day the professor is handed: the sections of his
# Morning Briefing have content, his commit control is dead, his Client is
# `firm`, and the whole thing is the same after a second run.
RSpec.describe Demo::Seed do
  def plaintiff = laid.demo.plaintiff_side

  def demo_day = laid.demo.days.find_by!(ordinal: described_class::DEMO_DAY)

  def identifiers(entries) = entries.map(&:identifier)

  let(:laid) { described_class.call }

  describe "the Day the player sits down on" do
    it "opens with the Day it must be — a served Exhibit exists no earlier" do
      expect(described_class::DEMO_DAY).to eq(3)
      expect(demo_day).not_to be_closed
      expect(laid.demo.days.where.not(closed_at: nil).map(&:ordinal)).to eq([1, 2])
    end

    it "hands him a full Budget, whatever he spent on the Days before" do
      budget = plaintiff.budget_on(demo_day)

      expect(budget.remaining_in(DayBudget::PREPARATION)).to eq(8)
      expect(budget.remaining_in(DayBudget::EXCHANGE)).to eq(2)
    end

    it "fills the briefing's landed, served and open-hand sections" do
      briefing = MorningBriefing.for(plaintiff, day: demo_day)

      expect(identifiers(briefing.landed)).to include("statement_to_the_trade_press")
      expect(identifiers(briefing.served)).to eq(["deposition_of_the_supervisor"])
      expect(identifiers(briefing.what_you_start_with))
        .to contain_exactly("the_termination_letter", "the_claimants_own_notes")
    end

    it "leaves him an Exhibit to ride his own Offer" do
      personnel_file = plaintiff.case_file_documents.joins(:case_document)
        .find_by!(case_documents: {identifier: "personnel_file"})

      expect(personnel_file).to be_playable
    end

    it "puts the defendant's committed Offer on the other track" do
      board = TermsBoard.for(plaintiff, day: demo_day)
      money = board.tracks.find { |track| track.term == "money" }

      expect(money.theirs.amount_cents).to eq(40_000_00)
      expect(money.ours).to be_nil
    end

    it "carries the Days 1–2 spends on his Docket" do
      docket = Docket.for(plaintiff)

      expect(docket.entries.map(&:kind)).to eq(
        [CaseAction::REQUEST_DOCUMENTS, CaseAction::RESEARCH_PRECEDENT, CaseAction::MANAGE_PRESS]
      )
      expect(docket.entries.map { |entry| entry.day.ordinal }).to eq([1, 1, 2])
    end

    # A phantom teammate on Days 1–2 would make this Side two members, and the
    # dead control the Docket teaches by — with the waiver that revives it —
    # would both evaporate.
    it "leaves the countersignature block dead in a lone hand" do
      expect(plaintiff.members.map(&:email)).to eq(["player@example.edu"])
      expect(plaintiff.seconders_other_than(plaintiff.members.first)).to be_empty
    end

    # `ready` sits at 0.8 of the bound and the Case authors one 0.25 Exhibit per
    # Client, so `firm` is arithmetic rather than a demo dial.
    it "answers a Consult with firm, after the deposition has moved him 0.25" do
      expect(plaintiff.reaction_band(as_of: Time.current)).to eq(CaseClientBand::FIRM)
      expect(plaintiff.bound_consumed).to eq(0.25)
    end
  end

  describe "the defendant's seeded morning" do
    it "commits under a real Second, at the exchange pool exactly" do
      side = laid.demo.defendant_side
      committed = side.committed_offer_on(demo_day)

      expect(committed.seconded_by).to be_present
      expect(committed.seconded_by).not_to eq(committed.staged_by)
      expect(side.budget_on(demo_day).remaining_in(DayBudget::EXCHANGE)).to eq(0)
    end

    it "files its own commitment, so the player's is the second and closes the Day" do
      expect(laid.demo.defendant_side.day_commitments.map { |filed| filed.day.ordinal })
        .to eq([1, 2, 3])
      expect(plaintiff.day_commitments.map { |filed| filed.day.ordinal }).to eq([1, 2])
    end
  end

  describe "the cold open" do
    it "sits at Day 1 open in the same Section, with nothing spent" do
      cold = laid.cold_open
      day_one = cold.days.find_by!(ordinal: 1)

      expect(cold.section).to eq(laid.demo.section)
      expect(day_one).not_to be_closed
      expect(cold.sides.map { |side| Docket.for(side) }).to all(be_empty)
    end

    it "deals the open hand and nothing else" do
      cold_plaintiff = cold_open_plaintiff = laid.cold_open.plaintiff_side

      expect(identifiers(CaseFile.for(cold_plaintiff).entries))
        .to contain_exactly("the_termination_letter", "the_claimants_own_notes")
      expect(cold_open_plaintiff.client_shifts).to be_empty
    end
  end

  describe "re-running it" do
    it "leaves the same state, at the same identifiers" do
      first = laid
      demo_id = first.demo.id
      before = Simulation.count

      second = described_class.call

      expect(second.demo.id).to eq(demo_id)
      expect(second.demo.id).to eq(described_class::DEMO_SIMULATION_ID)
      expect(second.cold_open.id).to eq(described_class::COLD_OPEN_SIMULATION_ID)
      expect(Simulation.count).to eq(before)
      expect(Organization.where(name: described_class::ORGANIZATION).count).to eq(1)
    end

    it "reaches nothing outside its own Organization" do
      laid
      other = Organization.create!(name: "Some Other College")
      section = other.sections.create!(name: "Contracts")
      untouched = Simulations::Create.call(
        section: section, case_version: laid.demo.case_version
      )

      described_class.call

      expect(Simulation.find_by(id: untouched.id)).to be_present
      expect(untouched.days.count).to eq(10)
    end
  end

  describe "the URLs it prints" do
    it "names the Simulation and the Day the screens will serve" do
      seed = described_class.new(base_url: "http://localhost:3000")
      laid_out = seed.call

      expect(seed.url_for(laid_out.demo))
        .to eq("http://localhost:3000/simulations/900001/days/3")
      expect(seed.url_for(laid_out.cold_open, day: 1))
        .to eq("http://localhost:3000/simulations/900002/days/1")
    end
  end
end
