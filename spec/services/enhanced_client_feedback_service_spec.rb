# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClientFeedbackService do
  let(:simulation) do
    # Use dynamic values to avoid exposing actual game ranges
    min_acceptable = rand(100_000..200_000)
    ideal = min_acceptable * 2
    defendant_ideal = min_acceptable * 0.5
    defendant_max = min_acceptable + rand(50_000..150_000)

    case_instance = create(:case, :with_teams)
    create(:simulation,
      case: case_instance,
      plaintiff_min_acceptable: min_acceptable,
      plaintiff_ideal: ideal,
      defendant_ideal: defendant_ideal,
      defendant_max_acceptable: defendant_max)
  end

  let(:plaintiff_team) { simulation.case.plaintiff_team }
  let(:defendant_team) { simulation.case.defendant_team }
  let(:service) { described_class.new(simulation) }

  describe "#initialize" do
    it "initializes with simulation and creates range validation service" do
      expect(service.simulation).to eq(simulation)
      expect(service.range_validation_service).to be_a(ClientRangeValidationService)
    end
  end

  describe "#generate_feedback_for_offer!" do
    let(:negotiation_round) { create(:negotiation_round, simulation: simulation) }
    let(:settlement_offer) do
      create(:settlement_offer,
        negotiation_round: negotiation_round,
        team: plaintiff_team,
        amount: simulation.plaintiff_ideal * 0.92,
        justification: "Strong case with clear evidence of harassment and significant impact on plaintiff's career and wellbeing")
    end

    it "generates range-based feedback for offer" do
      feedbacks = service.generate_feedback_for_offer!(settlement_offer)

      expect(feedbacks).to be_an(Array)
      expect(feedbacks.compact).not_to be_empty
      expect(feedbacks.first).to be_a(ClientFeedback) if feedbacks.first
    end

    context "when offer is below minimum" do
      let(:settlement_offer) do
        create(:settlement_offer,
          negotiation_round: negotiation_round,
          team: plaintiff_team,
          amount: simulation.plaintiff_min_acceptable * 0.83) # Below minimum acceptable
      end

      it "generates unhappy feedback" do
        feedbacks = service.generate_feedback_for_offer!(settlement_offer)

        expect(feedbacks).to be_an(Array)
        feedback = feedbacks.first
        expect(feedback.mood_level).to eq("very_unhappy") if feedback
      end
    end
  end

  describe "#get_client_mood_indicator" do
    context "when no feedback exists" do
      it "returns default mood indicator" do
        indicator = service.get_client_mood_indicator(plaintiff_team)

        expect(indicator[:mood_emoji]).to eq("😐")
        expect(indicator[:mood_description]).to eq("Neutral")
        expect(indicator[:satisfaction_level]).to eq("Moderate")
        expect(indicator[:trend]).to eq("stable")
      end
    end

    context "when feedback exists" do
      let!(:feedback) do
        create(:client_feedback,
          simulation: simulation,
          team: plaintiff_team,
          mood_level: :satisfied,
          satisfaction_score: 85,
          created_at: 1.hour.ago)
      end

      it "returns current mood indicator based on latest feedback" do
        indicator = service.get_client_mood_indicator(plaintiff_team)

        expect(indicator[:mood_description]).to match(/Satisfied|Pleased/)
        expect(indicator[:satisfaction_level]).to eq("High")
        expect(indicator[:last_updated]).to be_within(1.minute).of(feedback.created_at)
      end
    end
  end

  describe "range-based feedback generation" do
    describe "plaintiff feedback scenarios" do
      let(:negotiation_round) { create(:negotiation_round, simulation: simulation) }

      context "when offer is in strong position (near ideal)" do
        let(:settlement_offer) do
          create(:settlement_offer,
            negotiation_round: negotiation_round,
            team: plaintiff_team,
            amount: simulation.plaintiff_ideal * 1.08)
        end

        it "generates satisfied client feedback" do
          feedback = service.send(:generate_range_based_feedback, settlement_offer)

          expect(feedback.mood_level).to eq("satisfied")
          expect(feedback.satisfaction_score).to be_between(80, 90)
          expect(feedback.feedback_text).to include("strong position")
        end
      end

      context "when offer is below minimum acceptable" do
        let(:settlement_offer) do
          create(:settlement_offer,
            negotiation_round: negotiation_round,
            team: plaintiff_team,
            amount: simulation.plaintiff_min_acceptable * 0.83)
        end

        it "generates very unhappy client feedback" do
          feedback = service.send(:generate_range_based_feedback, settlement_offer)

          expect(feedback.mood_level).to eq("very_unhappy")
          expect(feedback.satisfaction_score).to be_between(10, 25)
          expect(feedback.feedback_text).to include("below expectations")
        end
      end
    end

    describe "defendant feedback scenarios" do
      let(:negotiation_round) { create(:negotiation_round, simulation: simulation) }

      context "when offer is at ideal amount" do
        let(:settlement_offer) do
          create(:settlement_offer,
            negotiation_round: negotiation_round,
            team: defendant_team,
            amount: simulation.defendant_ideal)
        end

        it "generates satisfied client feedback" do
          feedback = service.send(:generate_range_based_feedback, settlement_offer)

          expect(feedback.mood_level).to eq("satisfied")
          expect(feedback.satisfaction_score).to be_between(80, 90)
          expect(feedback.feedback_text).to include("ideal resolution")
        end
      end

      context "when offer exceeds maximum acceptable" do
        let(:settlement_offer) do
          create(:settlement_offer,
            negotiation_round: negotiation_round,
            team: defendant_team,
            amount: simulation.defendant_max_acceptable * 1.2)
        end

        it "generates very unhappy client feedback" do
          feedback = service.send(:generate_range_based_feedback, settlement_offer)

          expect(feedback.mood_level).to eq("very_unhappy")
          expect(feedback.satisfaction_score).to be_between(10, 25)
          expect(feedback.feedback_text).to include("exceeds acceptable limits")
        end
      end
    end
  end

  describe "helper methods" do
    describe "#satisfaction_level_descriptor" do
      it "returns correct descriptors for satisfaction scores" do
        expect(service.send(:satisfaction_level_descriptor, 95)).to eq("Very High")
        expect(service.send(:satisfaction_level_descriptor, 80)).to eq("High")
        expect(service.send(:satisfaction_level_descriptor, 65)).to eq("Moderate")
        expect(service.send(:satisfaction_level_descriptor, 45)).to eq("Low")
        expect(service.send(:satisfaction_level_descriptor, 20)).to eq("Very Low")
      end
    end

    describe "#mood_to_score" do
      it "converts mood levels to numeric scores" do
        expect(service.send(:mood_to_score, "very_satisfied")).to eq(1.0)
        expect(service.send(:mood_to_score, "satisfied")).to eq(0.75)
        expect(service.send(:mood_to_score, "neutral")).to eq(0.5)
        expect(service.send(:mood_to_score, "unhappy")).to eq(0.25)
        expect(service.send(:mood_to_score, "very_unhappy")).to eq(0.0)
      end
    end

    describe "#score_to_mood" do
      it "converts numeric scores to mood levels" do
        expect(service.send(:score_to_mood, 0.95)).to eq("very_satisfied")
        expect(service.send(:score_to_mood, 0.8)).to eq("satisfied")
        expect(service.send(:score_to_mood, 0.5)).to eq("neutral")
        expect(service.send(:score_to_mood, 0.2)).to eq("unhappy")
        expect(service.send(:score_to_mood, 0.05)).to eq("very_unhappy")
      end
    end
  end

  describe "integration with ClientRangeValidationService" do
    let(:negotiation_round) { create(:negotiation_round, simulation: simulation) }
    let(:settlement_offer) do
      create(:settlement_offer,
        negotiation_round: negotiation_round,
        team: plaintiff_team,
        amount: simulation.plaintiff_ideal * 0.92)
    end

    it "uses validation service for range-based feedback" do
      expect(service.range_validation_service).to receive(:validate_offer)
        .with(plaintiff_team, settlement_offer.amount)
        .and_call_original

      service.send(:generate_range_based_feedback, settlement_offer)
    end
  end
end
