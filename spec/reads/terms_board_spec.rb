# frozen_string_literal: true

require "rails_helper"

# Where the shape of the deal is visible. Three slots per Term and three ways to
# be silent, and the board keeps them apart: nobody has offered it, somebody has
# offered it without a figure, or this Client is indifferent about it.
RSpec.describe TermsBoard do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:opponent) { simulation.defendant_side }
  let(:day) { simulation.days.first }
  let(:dana) { a_user(organization: simulation.section.organization) }
  let(:priya) do
    a_user(organization: simulation.section.organization, name: "Priya Raman",
      email: "priya@example.edu")
  end

  def board(on: day) = described_class.for(side, day: on)

  def track(key, on: day) = board(on: on).tracks.find { |row| row.term == key }

  # There is no roster yet, so a teammate joins a Team by acting for it — which
  # is also what makes them eligible to second.
  def a_teammate_of(for_side, on: day)
    Days::Command.apply(act: :spend, side: for_side, day: on, by: priya,
      kind: CaseAction::CONSULT_CLIENT)
    priya
  end

  def stage(for_side, terms, on: day, by: dana)
    Offers::Stage.call(side: for_side, day: on, by: by, terms: terms)
  end

  def commit(for_side, on: day, by: dana)
    Days::Command.apply(act: :commit_offer, side: for_side, day: on, by: by,
      seconded_by: a_teammate_of(for_side, on: on))
  end

  it "carries a track per Term, in the order the Case authors its vocabulary" do
    expect(board.tracks.map(&:term)).to eq(simulation.case_version.terms.order(:id).map(&:key))
  end

  describe "the Team's own position" do
    it "is the draft on today's table" do
      stage(side, {CaseTerm::MONEY => 250_000_00})

      expect(track("money").ours.amount_cents).to eq(250_000_00)
      expect(track("money").ours_staged).to be(true)
    end

    # A Team with no draft today has not withdrawn what it already put in front
    # of the other Side.
    it "falls back to the last Offer the Team actually committed" do
      stage(side, {CaseTerm::MONEY => 250_000_00})
      commit(side)
      Days::Open.call(simulation.days.second)

      tomorrow = track("money", on: simulation.days.second)
      expect(tomorrow.ours.amount_cents).to eq(250_000_00)
      expect(tomorrow.ours_staged).to be(false)
    end

    it "is silent before the Team has taken any position at all" do
      expect(track("money").ours).to be_nil
    end
  end

  describe "the other Side's track" do
    before do
      stage(opponent, {CaseTerm::MONEY => 40_000_00, "apology" => nil})
      commit(opponent)
    end

    it "carries their last committed Offer" do
      expect(track("money").theirs.amount_cents).to eq(40_000_00)
    end

    # A Term on the table without a figure is a position, not an absence: a
    # Team offering an apology is offering an apology.
    it "carries a Term they offered without a figure" do
      expect(track("apology").theirs).to be_present
      expect(track("apology").theirs).not_to be_money
    end

    # An offer of nothing is a position somebody took, and this did not happen.
    it "is silent on a Term their Offer never mentioned, rather than zero" do
      expect(track("nda").theirs).to be_nil
    end

    # A composite of the furthest each Term ever reached is a position nobody
    # put on the table.
    it "reads their last Offer whole rather than a per-Term latest" do
      second_day = simulation.days.second
      Days::Open.call(second_day)
      stage(opponent, {CaseTerm::MONEY => 45_000_00}, on: second_day)
      commit(opponent, on: second_day)

      expect(track("money", on: second_day).theirs.amount_cents).to eq(45_000_00)
      expect(track("apology", on: second_day).theirs).to be_nil
    end

    # Per ADR 0002 the drafts live in their own table so that a cross-Side read
    # structurally cannot reach a live position.
    it "never shows their live draft" do
      third_day = simulation.days.find_by!(ordinal: 3)
      Days::Open.call(simulation.days.second)
      Days::Open.call(third_day)
      stage(opponent, {CaseTerm::MONEY => 30_000_00}, on: third_day)

      expect(track("money", on: third_day).theirs.amount_cents).to eq(40_000_00)
    end
  end

  # Every slot is as of the Day the board is read for. Live play cannot reach a
  # committed Offer on a later Day — a commit needs an open Day with a Budget
  # row, and `Days::Close` opens the next Day only as it closes this one — but
  # the Instructor reads a running Simulation and the Debrief reads a finished
  # one, and a board that mixed a Day-scoped draft with a global Offer would
  # show them a position that had not been taken yet.
  describe "a Day read after a later Offer was committed" do
    before do
      stage(side, {CaseTerm::MONEY => 250_000_00})
      stage(opponent, {CaseTerm::MONEY => 40_000_00})
      commit(side)
      commit(opponent)

      second_day = simulation.days.second
      Days::Open.call(second_day)
      stage(side, {CaseTerm::MONEY => 200_000_00}, on: second_day)
      stage(opponent, {CaseTerm::MONEY => 60_000_00}, on: second_day)
      commit(side, on: second_day)
      commit(opponent, on: second_day)
    end

    it "shows the other Side's Offer as it stood that Day" do
      expect(track("money").theirs.amount_cents).to eq(40_000_00)
    end

    it "shows the Team's own draft as it stood that Day" do
      expect(track("money").ours.amount_cents).to eq(250_000_00)
    end

    it "still reads the latest on the Day being played" do
      expect(track("money", on: simulation.days.second).theirs.amount_cents).to eq(60_000_00)
    end
  end

  # The Team's own slot falls back to its last committed Offer on a Day it
  # staged nothing, and that fallback is as of the Day too: a Day the Team was
  # silent on is not a Day it had already taken next week's position.
  describe "a silent Day read after the Team committed later" do
    before do
      second_day = simulation.days.second
      Days::Open.call(second_day)
      stage(side, {CaseTerm::MONEY => 200_000_00}, on: second_day)
      commit(side, on: second_day)
    end

    it "leaves the earlier Day silent rather than showing the later Offer" do
      expect(track("money").ours).to be_nil
    end
  end

  describe "the Client's stated aspiration" do
    it "carries what this Team's own Client says they want" do
      expect(track("money").aspiration.amount_cents).to eq(250_000_00)
    end

    it "carries a Term wanted without a figure as wanted" do
      expect(track("apology").aspiration).to be_present
      expect(track("apology").aspiration).not_to be_money
    end

    # Sparse by authoring: a Term with none is one this Client is indifferent
    # about, and its track carries the two live positions and no marker.
    it "is silent on a Term the Client is indifferent about" do
      expect(track("training").aspiration).to be_nil
    end

    it "is the Team's own Client's and never the other Side's" do
      expect(described_class.for(opponent, day: day).tracks
        .find { |row| row.term == "money" }.aspiration.amount_cents).to eq(25_000_00)
    end

    # An aspiration does not move, which is what lets it be shown: a Client's
    # stated demands never reveal that they have softened.
    it "does not move when the Client does" do
      Days::Command.apply(act: :spend, side: side, day: day, by: dana,
        kind: CaseAction::DEPOSE_WITNESS)
      Days::Open.call(simulation.days.second)
      Days::Open.call(simulation.days.find_by!(ordinal: 3))

      expect(side.bound_consumed).to eq(0.25)
      expect(track("money", on: simulation.days.find_by!(ordinal: 3))
        .aspiration.amount_cents).to eq(250_000_00)
    end
  end
end
