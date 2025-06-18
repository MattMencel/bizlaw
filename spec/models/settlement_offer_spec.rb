# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SettlementOffer, type: :model do
  subject(:offer) { build(:settlement_offer) }

  describe 'associations' do
    it { is_expected.to belong_to(:negotiation_round) }
    it { is_expected.to belong_to(:team) }
    it { is_expected.to belong_to(:submitted_by).class_name('User') }
    it { is_expected.to have_many(:client_feedbacks).dependent(:nullify) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_presence_of(:justification) }
    it { is_expected.to validate_length_of(:justification).is_at_least(50).is_at_most(2000) }
    it { is_expected.to validate_presence_of(:submitted_at) }

    describe 'uniqueness' do
      let!(:existing_offer) { create(:settlement_offer) }

      it 'validates uniqueness of team per round' do
        new_offer = build(:settlement_offer,
                         negotiation_round: existing_offer.negotiation_round,
                         team: existing_offer.team)
        expect(new_offer).not_to be_valid
        expect(new_offer.errors[:team_id]).to include("can only submit one offer per round")
      end
    end

    describe 'custom validations' do
      let(:simulation) { create(:simulation, :active) }
      let(:team) { simulation.plaintiff_team }
      let(:round) { create(:negotiation_round, simulation: simulation) }

      it 'validates team_assigned_to_case' do
        unassigned_team = create(:team)
        offer.team = unassigned_team
        offer.negotiation_round = round
        expect(offer).not_to be_valid
        expect(offer.errors[:team]).to include("is not assigned to this case")
      end

      it 'validates offer_submitted_within_deadline' do
        offer.negotiation_round = round
        offer.submitted_at = round.deadline + 1.hour
        expect(offer).not_to be_valid
        expect(offer.errors[:submitted_at]).to include("cannot be after round deadline")
      end

      it 'validates amount_within_reasonable_bounds' do
        offer.negotiation_round = round
        offer.amount = 10_000_000 # Unreasonably high
        expect(offer).not_to be_valid
        expect(offer.errors[:amount]).to include("is unreasonably high for this case")
      end
    end
  end

  describe 'enums' do
    it { expect(subject).to define_enum_for(:offer_type).with_values(
      initial_demand: "initial_demand",
      counteroffer: "counteroffer",
      final_offer: "final_offer"
    ).with_prefix(:offer) }
  end

  describe 'instance methods' do
    let(:simulation) do
      create(:simulation, :active,
        plaintiff_min_acceptable: 150_000,
        plaintiff_ideal: 300_000,
        defendant_ideal: 75_000,
        defendant_max_acceptable: 250_000
      )
    end
    let(:plaintiff_team) { simulation.plaintiff_team }
    let(:defendant_team) { simulation.defendant_team }
    let(:round) { create(:negotiation_round, simulation: simulation, round_number: 2) }

    describe '#team_role' do
      it 'returns plaintiff for plaintiff team' do
        offer = create(:settlement_offer, negotiation_round: round, team: plaintiff_team)
        expect(offer.team_role).to eq('plaintiff')
      end

      it 'returns defendant for defendant team' do
        offer = create(:settlement_offer, negotiation_round: round, team: defendant_team)
        expect(offer.team_role).to eq('defendant')
      end
    end

    describe '#is_plaintiff_offer?' do
      it 'returns true for plaintiff team' do
        offer = create(:settlement_offer, negotiation_round: round, team: plaintiff_team)
        expect(offer).to be_is_plaintiff_offer
      end

      it 'returns false for defendant team' do
        offer = create(:settlement_offer, negotiation_round: round, team: defendant_team)
        expect(offer).not_to be_is_plaintiff_offer
      end
    end

    describe '#within_client_expectations?' do
      it 'returns true for plaintiff offer above minimum' do
        offer = create(:settlement_offer,
                      negotiation_round: round,
                      team: plaintiff_team,
                      amount: simulation.plaintiff_min_acceptable + 10000)
        expect(offer.within_client_expectations?).to be true
      end

      it 'returns false for plaintiff offer below minimum' do
        offer = create(:settlement_offer,
                      negotiation_round: round,
                      team: plaintiff_team,
                      amount: simulation.plaintiff_min_acceptable - 10000)
        expect(offer.within_client_expectations?).to be false
      end

      it 'returns true for defendant offer below maximum' do
        offer = create(:settlement_offer,
                      negotiation_round: round,
                      team: defendant_team,
                      amount: simulation.defendant_max_acceptable - 10000)
        expect(offer.within_client_expectations?).to be true
      end

      it 'returns false for defendant offer above maximum' do
        offer = create(:settlement_offer,
                      negotiation_round: round,
                      team: defendant_team,
                      amount: simulation.defendant_max_acceptable + 10000)
        expect(offer.within_client_expectations?).to be false
      end
    end

    describe '#quality_assessment' do
      let(:offer) { create(:settlement_offer, negotiation_round: round, team: plaintiff_team) }

      it 'returns a hash with total_score and breakdown' do
        assessment = offer.quality_assessment
        expect(assessment).to have_key(:total_score)
        expect(assessment).to have_key(:breakdown)
        expect(assessment[:breakdown]).to have_key(:justification)
        expect(assessment[:breakdown]).to have_key(:client_expectations)
        expect(assessment[:breakdown]).to have_key(:strategic_positioning)
        expect(assessment[:breakdown]).to have_key(:creativity)
      end

      it 'calculates a reasonable score' do
        assessment = offer.quality_assessment
        expect(assessment[:total_score]).to be_between(0, 100)
      end
    end
  end

  describe 'callbacks' do
    let(:simulation) { create(:simulation, :active) }
    let(:round) { create(:negotiation_round, simulation: simulation, round_number: 1) }
    let(:team) { simulation.plaintiff_team }

    describe 'set_offer_type' do
      it 'sets initial_demand for round 1' do
        offer = create(:settlement_offer, negotiation_round: round, team: team)
        expect(offer.offer_type).to eq('initial_demand')
      end

      it 'sets final_offer for final round' do
        final_round = create(:negotiation_round, simulation: simulation, round_number: 6)
        offer = create(:settlement_offer, negotiation_round: final_round, team: team)
        expect(offer.offer_type).to eq('final_offer')
      end

      it 'sets counteroffer for middle rounds' do
        middle_round = create(:negotiation_round, simulation: simulation, round_number: 3)
        offer = create(:settlement_offer, negotiation_round: middle_round, team: team)
        expect(offer.offer_type).to eq('counteroffer')
      end
    end
  end
end
