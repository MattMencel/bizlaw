# frozen_string_literal: true

require "rails_helper"
RSpec.describe GoogleAiService do
  let(:organization) { create(:organization) }
  let(:course) { create(:course, organization: organization) }
  let(:plaintiff_team) { create(:team, course: course) }
  let(:defendant_team) { create(:team, course: course) }
  let(:case_instance) do
    case_obj = create(:case, course: course)
    create(:case_team, case: case_obj, team: plaintiff_team, role: "plaintiff")
    create(:case_team, case: case_obj, team: defendant_team, role: "defendant")
    case_obj
  end
  let(:simulation) { create(:simulation, case: case_instance) }
  let(:negotiation_round) { create(:negotiation_round, simulation: simulation, round_number: 1) }
  let(:settlement_offer) do
    create(:settlement_offer,
      team: plaintiff_team,
      negotiation_round: negotiation_round,
      amount: 150_000)
  end

  let(:mock_client) { instance_double(Gemini::Controllers::Client) }
  let(:mock_response) do
    {
      'candidates' => [
        {
          'content' => {
            'parts' => [
              { 'text' => 'Mock AI response text' }
            ]
          }
        }
      ]
    }
  end

  before do
    allow(GoogleAI).to receive(:enabled?).and_return(true)
    allow(GoogleAI).to receive(:client).and_return(mock_client)
    allow(GoogleAI).to receive(:model).and_return("gemini-2.0-flash-lite")
  end

  describe "#initialize" do
    it "creates service instance" do
      service = described_class.new
      expect(service).to be_an_instance_of(described_class)
    end
  end

  describe "#generate_settlement_feedback" do
    let(:service) { described_class.new }

    context "when AI service is enabled" do
      let(:ai_response_text) do
        "Based on the settlement offer of $150,000, the client shows moderate satisfaction. This positioning demonstrates strategic thinking while maintaining negotiation flexibility."
      end

      before do
        # Create a mock response that matches the expected format
        mock_response_with_text = {
          'candidates' => [
            {
              'content' => {
                'parts' => [
                  { 'text' => ai_response_text }
                ]
              }
            }
          ]
        }
        allow(mock_client).to receive(:generate_content).and_return(mock_response_with_text)
      end

      it "generates contextual feedback using AI" do
        result = service.generate_settlement_feedback(settlement_offer)

        expect(result).to include(:feedback_text)
        expect(result).to include(:mood_level)
        expect(result).to include(:satisfaction_score)
        expect(result).to include(:source)
        expect(result[:source]).to eq("ai")
        expect(result[:feedback_text]).to include("settlement")
      end

      it "calls Google AI client with proper parameters" do
        service.generate_settlement_feedback(settlement_offer)

        expect(mock_client).to have_received(:generate_content) do |args|
          expect(args).to be_a(Hash)
          expect(args[:contents][:parts][:text]).to be_a(String)
        end
      end

      it "includes settlement context in AI prompt" do
        service.generate_settlement_feedback(settlement_offer)

        expect(mock_client).to have_received(:generate_content) do |args|
          prompt = args[:contents][:parts][:text]
          expect(prompt).to include("$150,000")
          expect(prompt).to include("plaintiff")
          expect(prompt).to include("Negotiation round: 1")
        end
      end
    end

    context "when AI service is disabled" do
      before do
        allow(GoogleAI).to receive(:enabled?).and_return(false)
      end

      it "returns fallback response" do
        result = service.generate_settlement_feedback(settlement_offer)

        expect(result[:source]).to eq("fallback")
        expect(result[:feedback_text]).to be_present
        expect(result[:mood_level]).to be_present
        expect(result[:satisfaction_score]).to be_a(Integer)
      end
    end

    context "when AI service throws error" do
      before do
        allow(mock_client).to receive(:generate_content).and_raise(StandardError, "API Error")
      end

      it "handles errors gracefully" do
        result = service.generate_settlement_feedback(settlement_offer)

        expect(result[:source]).to eq("fallback")
        expect(result[:error_handled]).to be true
      end

      it "logs the error" do
        allow(Rails.logger).to receive(:error)
        
        service.generate_settlement_feedback(settlement_offer)
        
        expect(Rails.logger).to have_received(:error).with(/GoogleAI error/)
      end
    end
  end

  describe "#analyze_negotiation_state" do
    let(:service) { described_class.new }
    let(:current_round) { 3 }

    before do
      # Create settlement offers for both teams
      create(:settlement_offer,
        team: plaintiff_team,
        negotiation_round: negotiation_round,
        amount: 200_000)
      create(:settlement_offer,
        team: defendant_team,
        negotiation_round: negotiation_round,
        amount: 100_000)
    end

    context "when AI service is available" do
      let(:ai_analysis) do
        "Strategic analysis for round 3: Significant gap exists between positions. Plaintiff should consider more flexible terms. Defendant may need to increase offer to show good faith."
      end

      before do
        mock_analysis_response = {
          'candidates' => [
            {
              'content' => {
                'parts' => [
                  { 'text' => ai_analysis }
                ]
              }
            }
          ]
        }
        allow(mock_client).to receive(:generate_content).and_return(mock_analysis_response)
      end

      it "provides strategic analysis" do
        result = service.analyze_negotiation_state(simulation, current_round)

        expect(result[:advice]).to be_present
        expect(result[:round_context]).to eq(current_round)
        expect(result[:source]).to eq("ai")
      end

      it "includes negotiation context in prompt" do
        service.analyze_negotiation_state(simulation, current_round)

        expect(mock_client).to have_received(:generate_content) do |args|
          prompt = args[:contents][:parts][:text]
          expect(prompt).to include("Current round: 3")
          # Note: Offers may not be included if no settlement offers exist yet
        end
      end
    end

    context "when AI service fails" do
      before do
        allow(mock_client).to receive(:generate_content).and_raise(StandardError)
      end

      it "provides fallback analysis" do
        result = service.analyze_negotiation_state(simulation, current_round)

        expect(result[:source]).to eq("fallback")
        expect(result[:advice]).to be_present
      end
    end
  end

  describe "#analyze_settlement_options" do
    let(:service) { described_class.new }
    let(:analysis_round) { create(:negotiation_round, simulation: simulation, round_number: 2) }
    let(:plaintiff_offer) { create(:settlement_offer, team: plaintiff_team, negotiation_round: analysis_round, amount: 250_000) }
    let(:defendant_offer) { create(:settlement_offer, team: defendant_team, negotiation_round: analysis_round, amount: 100_000) }

    context "with large settlement gap" do
      let(:ai_suggestions) do
        "Creative settlement options: 1) Structured payments over 3 years 2) Performance-based milestones 3) Non-monetary terms including policy changes. Risk assessment: High gap requires innovative approach."
      end

      before do
        mock_suggestions_response = {
          'candidates' => [
            {
              'content' => {
                'parts' => [
                  { 'text' => ai_suggestions }
                ]
              }
            }
          ]
        }
        allow(mock_client).to receive(:generate_content).and_return(mock_suggestions_response)
      end

      it "suggests creative solutions" do
        result = service.analyze_settlement_options(plaintiff_offer, defendant_offer)

        expect(result[:creative_options]).to be_present
        expect(result[:risk_assessment]).to be_present
        expect(result[:gap_analysis]).to include(gap_size: 150_000)
      end

      it "provides role-specific perspectives" do
        result = service.analyze_settlement_options(plaintiff_offer, defendant_offer)

        expect(result[:plaintiff_perspective]).to be_present
        expect(result[:defendant_perspective]).to be_present
      end
    end
  end

  describe "#fallback_feedback" do
    let(:service) { described_class.new }

    it "provides structured fallback for plaintiff offers" do
      result = service.fallback_feedback(settlement_offer)

      expect(result[:source]).to eq("fallback")
      expect(result[:feedback_text]).to include("Client")
      expect(result[:mood_level]).to be_in(%w[satisfied neutral unhappy])
      expect(result[:satisfaction_score]).to be_between(1, 100)
    end

    it "includes cost information" do
      result = service.fallback_feedback(settlement_offer)

      expect(result[:cost]).to eq(0)
    end
  end

  describe "#enabled?" do
    let(:service) { described_class.new }

    it "delegates to GoogleAI configuration" do
      allow(GoogleAI).to receive(:enabled?).and_return(true)
      
      expect(service.enabled?).to be true
      expect(GoogleAI).to have_received(:enabled?).at_least(:once)
    end
  end

  describe "prompt generation" do
    let(:service) { described_class.new }

    describe "#build_settlement_prompt" do
      it "includes all relevant context" do
        prompt = service.send(:build_settlement_prompt, settlement_offer)

        expect(prompt).to include("Settlement offer: $150,000")
        expect(prompt).to include("plaintiff")
        expect(prompt).to include("Negotiation round: 1")
        expect(prompt).to include("legal education simulation")
      end

      it "includes role-specific context" do
        defendant_negotiation_round = create(:negotiation_round, simulation: simulation, round_number: 2)
        defendant_offer = create(:settlement_offer, team: defendant_team, negotiation_round: defendant_negotiation_round, amount: 75_000)
        prompt = service.send(:build_settlement_prompt, defendant_offer)

        expect(prompt).to include("defendant")
        expect(prompt).to include("$75,000")
      end
    end

    describe "#build_analysis_prompt" do
      it "includes negotiation state context" do
        prompt = service.send(:build_analysis_prompt, simulation, 3)

        expect(prompt).to include("Current round: 3")
        expect(prompt).to include("strategic analysis")
        expect(prompt).to include("negotiation")
      end
    end
  end

  describe "response parsing" do
    let(:service) { described_class.new }

    describe "#parse_ai_feedback" do
      it "extracts sentiment and guidance from AI response" do
        ai_text = "Client satisfaction: moderate. Strategic guidance: Consider more flexible terms."
        
        result = service.send(:parse_ai_feedback, ai_text, settlement_offer)

        expect(result[:mood_level]).to be_present
        expect(result[:satisfaction_score]).to be_between(1, 100)
        expect(result[:strategic_guidance]).to be_present
      end
    end

    describe "#determine_mood_from_text" do
      it "correctly identifies positive sentiment" do
        mood = service.send(:determine_mood_from_text, "Client is very pleased and satisfied")
        expect(mood).to eq("very_satisfied")
      end

      it "correctly identifies negative sentiment" do
        mood = service.send(:determine_mood_from_text, "Client is unhappy and disappointed")
        expect(mood).to eq("unhappy")
      end

      it "defaults to neutral for unclear sentiment" do
        mood = service.send(:determine_mood_from_text, "Client is reviewing the offer")
        expect(mood).to eq("neutral")
      end
    end
  end

  describe "error handling and resilience" do
    let(:service) { described_class.new }

    context "when API rate limit is exceeded" do
      before do
        allow(mock_client).to receive(:generate_content).and_raise(StandardError, "Rate limit exceeded")
      end

      it "gracefully falls back to local feedback" do
        result = service.generate_settlement_feedback(settlement_offer)

        expect(result[:source]).to eq("fallback")
        expect(result[:rate_limited]).to be true
      end
    end

    context "when network is unavailable" do
      before do
        allow(mock_client).to receive(:generate_content).and_raise(Timeout::Error)
      end

      it "handles network errors" do
        result = service.generate_settlement_feedback(settlement_offer)

        expect(result[:source]).to eq("fallback")
        expect(result[:network_error]).to be true
      end
    end
  end

  # Helper method for array inclusion testing
  def be_in(array)
    satisfy { |value| array.include?(value) }
  end
end