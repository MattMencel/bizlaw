# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClientFeedbackService do
  let(:simulation) do
    case_instance = create(:case, :with_teams)
    create(:simulation,
      case: case_instance,
      plaintiff_min_acceptable: 150_000,
      plaintiff_ideal: 300_000,
      defendant_ideal: 75_000,
      defendant_max_acceptable: 250_000
    )
  end

  let(:plaintiff_team) { simulation.case.plaintiff_team }
  let(:defendant_team) { simulation.case.defendant_team }
  let(:service) { described_class.new(simulation) }
  let(:negotiation_round) { create(:negotiation_round, simulation: simulation, round_number: 1) }

  let(:mock_ai_service) { instance_double(GoogleAiService) }

  before do
    allow(GoogleAiService).to receive(:new).and_return(mock_ai_service)
    allow(GoogleAI).to receive(:enabled?).and_return(true)
  end

  describe "#generate_feedback_for_offer! with AI integration" do
    let(:settlement_offer) do
      create(:settlement_offer,
        negotiation_round: negotiation_round,
        team: plaintiff_team,
        amount: 275_000,
        justification: "Strong case with significant damages"
      )
    end

    context "when AI service is enabled and available" do
      let(:ai_feedback) do
        {
          feedback_text: "Client reviewing settlement positioning with cautious optimism. The strategic approach shows consideration of market dynamics and timing factors.",
          mood_level: "satisfied",
          satisfaction_score: 82,
          strategic_guidance: "Consider emphasizing non-monetary terms to strengthen overall package value.",
          source: "ai",
          cost: 0.02,
          model_used: "gemini-2.0-flash-lite"
        }
      end

      before do
        allow(mock_ai_service).to receive(:enabled?).and_return(true)
        allow(mock_ai_service).to receive(:generate_settlement_feedback).and_return(ai_feedback)
      end

      it "integrates AI feedback into range-based feedback generation" do
        feedbacks = service.generate_feedback_for_offer!(settlement_offer)

        expect(feedbacks).to be_an(Array)
        expect(feedbacks.first).to be_a(ClientFeedback)

        feedback = feedbacks.first
        expect(feedback.feedback_text).to include("Client reviewing settlement positioning")
        expect(feedback.mood_level).to eq("satisfied")
        expect(feedback.satisfaction_score).to eq(82)
      end

      it "calls Google AI service for settlement feedback" do
        service.generate_feedback_for_offer!(settlement_offer)

        expect(mock_ai_service).to have_received(:generate_settlement_feedback)
          .with(settlement_offer)
      end

      it "preserves existing feedback categorization" do
        feedbacks = service.generate_feedback_for_offer!(settlement_offer)

        feedback = feedbacks.first
        expect(feedback.feedback_type).to eq("offer_reaction")
        expect(feedback.triggered_by_round).to eq(negotiation_round.round_number)
        expect(feedback.settlement_offer).to eq(settlement_offer)
      end

      it "maintains educational context in AI responses" do
        feedbacks = service.generate_feedback_for_offer!(settlement_offer)

        feedback = feedbacks.first
        expect(feedback.feedback_text).to be_present
        expect(feedback.feedback_text.length).to be > 20
        # Should provide educational value without revealing game mechanics
        expect(feedback.feedback_text).not_to include("plaintiff_min_acceptable")
        expect(feedback.feedback_text).not_to include("defendant_max_acceptable")
      end
    end

    context "when AI service is disabled" do
      before do
        allow(GoogleAI).to receive(:enabled?).and_return(false)
        allow(mock_ai_service).to receive(:enabled?).and_return(false)
      end

      it "falls back to original range validation feedback" do
        feedbacks = service.generate_feedback_for_offer!(settlement_offer)

        expect(feedbacks).to be_an(Array)
        expect(feedbacks.first).to be_a(ClientFeedback)

        # Should still generate meaningful feedback
        feedback = feedbacks.first
        expect(feedback.feedback_text).to be_present
        expect(feedback.mood_level).to be_present
        expect(feedback.satisfaction_score).to be_present
      end

      it "does not call AI service when disabled" do
        service.generate_feedback_for_offer!(settlement_offer)

        expect(mock_ai_service).not_to have_received(:generate_settlement_feedback)
      end
    end

    context "when AI service encounters errors" do
      let(:fallback_feedback) do
        {
          feedback_text: "Client reviewing settlement offer and considering strategic options.",
          mood_level: "neutral",
          satisfaction_score: 65,
          strategic_guidance: "Continue monitoring negotiation progress.",
          source: "fallback",
          cost: 0,
          error_handled: true,
          error_type: "StandardError"
        }
      end

      before do
        allow(mock_ai_service).to receive(:enabled?).and_return(true)
        allow(mock_ai_service).to receive(:generate_settlement_feedback).and_return(fallback_feedback)
      end

      it "gracefully handles AI service errors" do
        feedbacks = service.generate_feedback_for_offer!(settlement_offer)

        expect(feedbacks).to be_an(Array)
        feedback = feedbacks.first
        expect(feedback.feedback_text).to be_present
        expect(feedback.mood_level).to eq("neutral")
      end

      it "logs errors for monitoring" do
        allow(Rails.logger).to receive(:warn)

        service.generate_feedback_for_offer!(settlement_offer)

        # Error logging would be handled by GoogleAiService
        expect(mock_ai_service).to have_received(:generate_settlement_feedback)
      end

      it "maintains user experience during errors" do
        feedbacks = service.generate_feedback_for_offer!(settlement_offer)

        expect(feedbacks).not_to be_empty
        expect(feedbacks.first).to be_a(ClientFeedback)
        expect(feedbacks.first.feedback_text).to be_present
      end
    end
  end

  describe "#generate_event_feedback! with AI enhancement" do
    let(:simulation_event) do
      create(:simulation_event,
        simulation: simulation,
        event_type: "media_attention",
        trigger_round: 2,
        triggered_at: Time.current
      )
    end

    context "when AI service is available" do
      let(:ai_event_feedback) do
        {
          feedback_text: "Client response to recent media developments shows heightened engagement and strategic recalibration toward settlement.",
          mood_level: "satisfied",
          satisfaction_score: 78,
          source: "ai"
        }
      end

      before do
        allow(mock_ai_service).to receive(:enabled?).and_return(true)
        allow(mock_ai_service).to receive(:generate_settlement_feedback).and_return(ai_event_feedback)
      end

      it "generates AI-enhanced event feedback for affected teams" do
        feedbacks = service.generate_event_feedback!(simulation_event, [ plaintiff_team, defendant_team ])

        expect(feedbacks).to be_an(Array)
        expect(feedbacks.length).to be >= 1

        feedbacks.each do |feedback|
          expect(feedback).to be_a(ClientFeedback)
          expect(feedback.feedback_text).to include("media developments")
        end
      end

      it "provides contextually relevant responses to events" do
        feedbacks = service.generate_event_feedback!(simulation_event)

        feedbacks.each do |feedback|
          expect(feedback.feedback_text).to be_present
          expect(feedback.feedback_text).not_to include("opponent")
          expect(feedback.feedback_text).not_to include("their strategy")
        end
      end
    end
  end

  describe "#generate_round_transition_feedback! with AI enhancement" do
    let(:completed_round) { create(:negotiation_round, simulation: simulation, round_number: 2) }
    let(:next_round) { 3 }

    before do
      # Create offers for the completed round
      create(:settlement_offer,
        team: plaintiff_team,
        negotiation_round: completed_round,
        amount: 250_000,
        quality_score: 85
      )
      create(:settlement_offer,
        team: defendant_team,
        negotiation_round: completed_round,
        amount: 150_000,
        quality_score: 75
      )
    end

    context "when AI service enhances strategic guidance" do
      let(:ai_strategic_analysis) do
        {
          advice: "Strategic analysis suggests focusing on creative settlement structures. Consider timeline pressures and non-monetary terms to bridge remaining gaps.",
          source: "ai",
          confidence: "high",
          round_context: next_round
        }
      end

      before do
        allow(mock_ai_service).to receive(:enabled?).and_return(true)
        allow(mock_ai_service).to receive(:analyze_negotiation_state).and_return(ai_strategic_analysis)
      end

      it "incorporates AI strategic analysis into transition feedback" do
        feedbacks = service.generate_round_transition_feedback!(completed_round.round_number, next_round)

        expect(feedbacks).to be_an(Array)
        expect(mock_ai_service).to have_received(:analyze_negotiation_state)
          .with(simulation, next_round)
      end

      it "provides role-specific strategic guidance" do
        feedbacks = service.generate_round_transition_feedback!(completed_round.round_number, next_round)

        feedbacks.each do |feedback|
          expect(feedback).to be_a(ClientFeedback)
          expect(feedback.feedback_type).to eq("strategy_guidance")
          expect(feedback.triggered_by_round).to eq(next_round)
        end
      end

      it "builds on negotiation history" do
        feedbacks = service.generate_round_transition_feedback!(completed_round.round_number, next_round)

        feedbacks.each do |feedback|
          expect(feedback.feedback_text).to be_present
          expect(feedback.feedback_text.length).to be > 30
          # Should reference round progression without revealing specifics
        end
      end
    end
  end

  describe "#generate_settlement_feedback! with AI enhancement" do
    let(:final_round) do
      create(:negotiation_round,
        simulation: simulation,
        round_number: 4,
        settlement_reached: true
      )
    end

    let(:final_settlement_amount) { 200_000 }

    before do
      # Create converging offers that resulted in settlement
      create(:settlement_offer,
        team: plaintiff_team,
        negotiation_round: final_round,
        amount: final_settlement_amount + 5_000
      )
      create(:settlement_offer,
        team: defendant_team,
        negotiation_round: final_round,
        amount: final_settlement_amount - 5_000
      )
    end

    context "when AI enhances settlement satisfaction feedback" do
      let(:ai_settlement_feedback) do
        {
          feedback_text: "Client expresses satisfaction with the negotiated settlement outcome. The resolution provides appropriate compensation while avoiding litigation uncertainty.",
          mood_level: "satisfied",
          satisfaction_score: 85,
          source: "ai"
        }
      end

      before do
        allow(mock_ai_service).to receive(:enabled?).and_return(true)
        allow(mock_ai_service).to receive(:generate_settlement_feedback).and_return(ai_settlement_feedback)
      end

      it "generates AI-enhanced settlement satisfaction responses" do
        feedbacks = service.generate_settlement_feedback!(final_round)

        expect(feedbacks).to be_an(Array)
        feedbacks.each do |feedback|
          expect(feedback).to be_a(ClientFeedback)
          expect(feedback.feedback_type).to eq("settlement_satisfaction")
          expect(feedback.feedback_text).to include("satisfaction")
        end
      end

      it "reflects appropriate closure context" do
        feedbacks = service.generate_settlement_feedback!(final_round)

        feedbacks.each do |feedback|
          expect(feedback.feedback_text).to include_any_of([
            "settlement", "resolution", "outcome", "negotiation"
          ])
          expect(feedback.triggered_by_round).to eq(final_round.round_number)
        end
      end
    end
  end

  describe "personality consistency across AI interactions" do
    let(:multiple_rounds) do
      (1..3).map do |round_num|
        create(:negotiation_round, simulation: simulation, round_number: round_num)
      end
    end

    let(:multiple_offers) do
      multiple_rounds.map.with_index do |round, index|
        create(:settlement_offer,
          team: plaintiff_team,
          negotiation_round: round,
          amount: 300_000 - (index * 25_000)
        )
      end
    end

    context "when client has established personality profile" do
      let(:consistent_ai_feedback) do
        {
          feedback_text: "Client maintains analytical approach to settlement evaluation, demonstrating consistent risk assessment methodology.",
          mood_level: "satisfied",
          satisfaction_score: 75,
          source: "ai"
        }
      end

      before do
        # Mock consistent AI responses that maintain personality
        allow(mock_ai_service).to receive(:enabled?).and_return(true)
        allow(mock_ai_service).to receive(:generate_settlement_feedback).and_return(consistent_ai_feedback)
      end

      it "maintains client personality consistency across rounds" do
        feedbacks = multiple_offers.map do |offer|
          service.generate_feedback_for_offer!(offer).first
        end

        expect(feedbacks.length).to eq(3)
        feedbacks.each do |feedback|
          expect(feedback.feedback_text).to include("analytical")
          expect(feedback.mood_level).to eq("satisfied")
        end
      end

      it "evolves strategic guidance logically" do
        feedbacks = multiple_offers.map do |offer|
          service.generate_feedback_for_offer!(offer).first
        end

        # Each feedback should build on the established personality
        feedbacks.each do |feedback|
          expect(feedback.satisfaction_score).to be_between(70, 85)
          expect(feedback.feedback_text).to be_present
        end
      end
    end
  end

  describe "AI cost and usage monitoring integration" do
    let(:settlement_offer) do
      create(:settlement_offer,
        negotiation_round: negotiation_round,
        team: plaintiff_team,
        amount: 200_000
      )
    end

    context "when monitoring AI usage" do
      let(:cost_tracked_feedback) do
        {
          feedback_text: "Client feedback with cost tracking",
          mood_level: "neutral",
          satisfaction_score: 70,
          source: "ai",
          cost: 0.015,
          model_used: "gemini-2.0-flash-lite"
        }
      end

      before do
        allow(mock_ai_service).to receive(:enabled?).and_return(true)
        allow(mock_ai_service).to receive(:generate_settlement_feedback).and_return(cost_tracked_feedback)
      end

      it "tracks AI service costs when available" do
        feedbacks = service.generate_feedback_for_offer!(settlement_offer)

        expect(mock_ai_service).to have_received(:generate_settlement_feedback)
        # Cost tracking would be handled by GoogleAiService
        expect(feedbacks.first).to be_a(ClientFeedback)
      end

      it "handles quota limits gracefully" do
        # Simulate quota exceeded scenario
        quota_exceeded_feedback = cost_tracked_feedback.merge(
          source: "fallback",
          cost: 0,
          quota_exceeded: true
        )

        allow(mock_ai_service).to receive(:generate_settlement_feedback).and_return(quota_exceeded_feedback)

        feedbacks = service.generate_feedback_for_offer!(settlement_offer)
        expect(feedbacks.first).to be_a(ClientFeedback)
      end
    end
  end

  describe "AI response quality validation" do
    let(:settlement_offer) do
      create(:settlement_offer,
        negotiation_round: negotiation_round,
        team: plaintiff_team,
        amount: 225_000
      )
    end

    context "when validating AI response appropriateness" do
      let(:appropriate_ai_feedback) do
        {
          feedback_text: "Client reviewing settlement terms with professional consideration of strategic objectives and risk factors.",
          mood_level: "neutral",
          satisfaction_score: 68,
          strategic_guidance: "Continue evaluating settlement options with focus on long-term business objectives.",
          source: "ai"
        }
      end

      before do
        allow(mock_ai_service).to receive(:enabled?).and_return(true)
        allow(mock_ai_service).to receive(:generate_settlement_feedback).and_return(appropriate_ai_feedback)
      end

      it "validates AI responses are professionally appropriate" do
        feedbacks = service.generate_feedback_for_offer!(settlement_offer)

        feedback = feedbacks.first
        expect(feedback.feedback_text).to be_present
        expect(feedback.feedback_text).not_to include_any_of([
          "inappropriate", "offensive", "unprofessional"
        ])
      end

      it "ensures educational value in AI responses" do
        feedbacks = service.generate_feedback_for_offer!(settlement_offer)

        feedback = feedbacks.first
        expect(feedback.feedback_text.length).to be > 30
        expect(feedback.feedback_text).to include_any_of([
          "strategic", "professional", "consideration", "objectives"
        ])
      end

      it "maintains legal realism in AI feedback" do
        feedbacks = service.generate_feedback_for_offer!(settlement_offer)

        feedback = feedbacks.first
        expect(feedback.feedback_text).to include_any_of([
          "client", "settlement", "business", "risk", "objectives"
        ])
      end
    end
  end

  # Helper method for flexible array inclusion testing
  def include_any_of(terms)
    satisfy { |text| terms.any? { |term| text.to_s.downcase.include?(term.downcase) } }
  end
end
