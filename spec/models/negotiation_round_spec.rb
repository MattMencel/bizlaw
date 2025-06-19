# frozen_string_literal: true

require "rails_helper"

RSpec.describe NegotiationRound, type: :model do
  subject(:round) { build(:negotiation_round) }

  describe "associations" do
    it { is_expected.to belong_to(:simulation) }
    it { is_expected.to have_many(:settlement_offers).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:round_number) }
    it { is_expected.to validate_numericality_of(:round_number).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:deadline) }

    describe "uniqueness" do
      let!(:existing_round) { create(:negotiation_round) }

      it "validates uniqueness of round_number scoped to simulation" do
        new_round = build(:negotiation_round,
          simulation: existing_round.simulation,
          round_number: existing_round.round_number)
        expect(new_round).not_to be_valid
      end
    end

    describe "custom validations" do
      it "validates deadline_in_future on create" do
        round.deadline = 1.hour.ago
        expect(round).not_to be_valid
        expect(round.errors[:deadline]).to include("must be in the future")
      end

      it "validates round_number_within_simulation_bounds" do
        round.simulation.total_rounds = 5
        round.round_number = 10
        expect(round).not_to be_valid
        expect(round.errors[:round_number]).to include("cannot exceed simulation total rounds")
      end
    end
  end

  describe "enums" do
    it {
      expect(subject).to define_enum_for(:status).with_values(
        pending: "pending",
        active: "active",
        plaintiff_submitted: "plaintiff_submitted",
        defendant_submitted: "defendant_submitted",
        both_submitted: "both_submitted",
        completed: "completed"
      ).with_prefix(:status)
    }
  end

  describe "instance methods" do
    let(:simulation) { create(:simulation, :active) }
    let(:plaintiff_team) { simulation.plaintiff_team }
    let(:defendant_team) { simulation.defendant_team }
    let(:round) { create(:negotiation_round, simulation: simulation) }

    describe "#start!" do
      it "transitions from pending to active" do
        expect(round.start!).to be true
        expect(round.status).to eq("active")
        expect(round.started_at).to be_present
      end

      it "returns false if not pending" do
        round.update!(status: :active)
        expect(round.start!).to be false
      end
    end

    describe "#both_teams_submitted?" do
      it "returns true when both teams have submitted offers" do
        create(:settlement_offer, negotiation_round: round, team: plaintiff_team)
        create(:settlement_offer, negotiation_round: round, team: defendant_team)
        expect(round.both_teams_submitted?).to be true
      end

      it "returns false when only one team has submitted" do
        create(:settlement_offer, negotiation_round: round, team: plaintiff_team)
        expect(round.both_teams_submitted?).to be false
      end
    end

    describe "#overdue?" do
      it "returns true when deadline has passed" do
        round.update!(deadline: 1.hour.ago)
        expect(round).to be_overdue
      end

      it "returns false when deadline is in future" do
        round.update!(deadline: 1.hour.from_now)
        expect(round).not_to be_overdue
      end
    end

    describe "#settlement_reached?" do
      it "returns true when offers are within 5% of each other" do
        create(:settlement_offer, negotiation_round: round, team: plaintiff_team, amount: 200000)
        create(:settlement_offer, negotiation_round: round, team: defendant_team, amount: 195000)
        expect(round.settlement_reached?).to be true
      end

      it "returns false when offers are far apart" do
        create(:settlement_offer, negotiation_round: round, team: plaintiff_team, amount: 300000)
        create(:settlement_offer, negotiation_round: round, team: defendant_team, amount: 100000)
        expect(round.settlement_reached?).to be false
      end
    end
  end
end
