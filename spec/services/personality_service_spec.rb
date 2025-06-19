# frozen_string_literal: true

require "rails_helper"

RSpec.describe PersonalityService, type: :service do
  describe ".available_personalities" do
    it "returns a list of defined personality types" do
      personalities = PersonalityService.available_personalities

      expect(personalities).to be_an(Array)
      expect(personalities).to include(
        hash_including(
          "type" => "aggressive",
          "name" => String,
          "traits" => Array,
          "communication_style" => Hash
        )
      )
    end

    it "includes required personality types for legal simulations" do
      personality_types = PersonalityService.available_personalities.map { |p| p["type"] }

      expect(personality_types).to include("aggressive", "cautious", "emotional", "pragmatic", "perfectionist")
    end

    it "includes detailed trait descriptions" do
      aggressive = PersonalityService.available_personalities.find { |p| p["type"] == "aggressive" }

      expect(aggressive["traits"]).to be_an(Array)
      expect(aggressive["traits"]).to all(be_a(String))
      expect(aggressive["communication_style"]).to include("tone", "language_patterns", "negotiation_approach")
    end
  end

  describe ".assign_personalities" do
    let(:case_instance) { create(:case, :sexual_harassment) }

    it "assigns different personalities to plaintiff and defendant" do
      personalities = PersonalityService.assign_personalities(case_instance)

      expect(personalities).to have_key(:plaintiff_personality)
      expect(personalities).to have_key(:defendant_personality)
      expect(personalities[:plaintiff_personality]).not_to eq(personalities[:defendant_personality])
    end

    it "returns valid personality types" do
      personalities = PersonalityService.assign_personalities(case_instance)
      available_types = PersonalityService.available_personalities.map { |p| p["type"] }

      expect(available_types).to include(personalities[:plaintiff_personality])
      expect(available_types).to include(personalities[:defendant_personality])
    end

    it "is deterministic for the same case" do
      personalities1 = PersonalityService.assign_personalities(case_instance)
      personalities2 = PersonalityService.assign_personalities(case_instance)

      expect(personalities1).to eq(personalities2)
    end

    it "assigns different personalities to different cases" do
      case2 = create(:case, :sexual_harassment)

      personalities1 = PersonalityService.assign_personalities(case_instance)
      personalities2 = PersonalityService.assign_personalities(case2)

      # At least one personality should be different between cases
      expect(personalities1 != personalities2).to be_truthy
    end
  end

  describe ".get_personality_traits" do
    it "returns traits for a valid personality type" do
      traits = PersonalityService.get_personality_traits("aggressive")

      expect(traits).to be_a(Hash)
      expect(traits).to include("type", "name", "traits", "communication_style")
    end

    it "raises error for invalid personality type" do
      expect {
        PersonalityService.get_personality_traits("invalid_personality")
      }.to raise_error(ArgumentError, /Unknown personality type/)
    end
  end

  describe ".personality_influences_satisfaction" do
    it "adjusts satisfaction based on personality type" do
      base_satisfaction = 70

      aggressive_satisfaction = PersonalityService.personality_influences_satisfaction(
        "aggressive", base_satisfaction, amount: 100_000, role: "plaintiff"
      )

      cautious_satisfaction = PersonalityService.personality_influences_satisfaction(
        "cautious", base_satisfaction, amount: 100_000, role: "plaintiff"
      )

      expect(aggressive_satisfaction).not_to eq(cautious_satisfaction)
    end

    it "applies different adjustments for different personalities" do
      base_satisfaction = 50
      amount = 150_000

      perfectionist = PersonalityService.personality_influences_satisfaction(
        "perfectionist", base_satisfaction, amount: amount, role: "plaintiff"
      )

      pragmatic = PersonalityService.personality_influences_satisfaction(
        "pragmatic", base_satisfaction, amount: amount, role: "plaintiff"
      )

      # Perfectionist should be harder to please
      expect(perfectionist).to be < pragmatic
    end

    it "considers role in satisfaction calculation" do
      plaintiff_satisfaction = PersonalityService.personality_influences_satisfaction(
        "aggressive", 70, amount: 200_000, role: "plaintiff"
      )

      defendant_satisfaction = PersonalityService.personality_influences_satisfaction(
        "aggressive", 70, amount: 200_000, role: "defendant"
      )

      expect(plaintiff_satisfaction).not_to eq(defendant_satisfaction)
    end
  end

  describe ".get_mood_adjustment" do
    it "adjusts mood based on personality" do
      base_mood = "neutral"

      emotional_mood = PersonalityService.get_mood_adjustment("emotional", base_mood, context: "positive_offer")
      expect(["satisfied", "very_satisfied"]).to include(emotional_mood)

      cautious_mood = PersonalityService.get_mood_adjustment("cautious", base_mood, context: "positive_offer")
      expect(cautious_mood).to eq("neutral") # More conservative response
    end

    it "handles negative contexts appropriately" do
      aggressive_mood = PersonalityService.get_mood_adjustment("aggressive", "neutral", context: "low_offer")
      expect(["unhappy", "very_unhappy"]).to include(aggressive_mood)
    end
  end

  describe ".build_personality_prompt" do
    let(:case_instance) { create(:case, :sexual_harassment) }
    let(:simulation) { create(:simulation, case: case_instance) }
    let(:round) { create(:negotiation_round, simulation: simulation) }
    let(:team) { create(:team) }
    let!(:case_team) { create(:case_team, case: case_instance, team: team, role: "plaintiff") }
    let(:settlement_offer) { create(:settlement_offer, amount: 150_000, negotiation_round: round, team: team) }
    let(:personality_type) { "aggressive" }

    it "builds a prompt with personality-specific language" do
      prompt = PersonalityService.build_personality_prompt(settlement_offer, personality_type, "plaintiff")

      expect(prompt).to include("aggressive")
      expect(prompt).to include("$150,000")
      expect(prompt).to include("plaintiff")
    end

    it "includes personality traits in the prompt" do
      prompt = PersonalityService.build_personality_prompt(settlement_offer, "cautious", "defendant")

      expect(prompt).to include("cautious")
      expect(prompt).to include("Careful consideration of all options")
    end

    it "adapts language patterns for different personalities" do
      aggressive_prompt = PersonalityService.build_personality_prompt(settlement_offer, "aggressive", "plaintiff")
      emotional_prompt = PersonalityService.build_personality_prompt(settlement_offer, "emotional", "plaintiff")

      expect(aggressive_prompt).to include("demanding")
      expect(emotional_prompt).to include("emotional")
    end
  end

  describe ".track_consistency" do
    let(:case_instance) { create(:case, :sexual_harassment) }
    let(:responses) { ["Response 1", "Response 2", "Response 3"] }

    it "creates a consistency tracking record" do
      expect {
        PersonalityService.track_consistency(case_instance, "aggressive", responses)
      }.to change(PersonalityConsistencyTracker, :count).by(1)
    end

    it "stores personality and response data" do
      tracker = PersonalityService.track_consistency(case_instance, "emotional", responses)

      expect(tracker.personality_type).to eq("emotional")
      expect(tracker.response_history).to eq(responses)
      expect(tracker.case).to eq(case_instance)
    end

    it "calculates consistency score" do
      tracker = PersonalityService.track_consistency(case_instance, "cautious", responses)

      expect(tracker.consistency_score).to be_between(0, 100)
    end
  end

  describe ".validate_personality_consistency" do
    let(:previous_responses) { ["We should carefully consider this offer", "A measured and thoughtful reaction"] }
    let(:new_response) { "We need to evaluate this conservative approach carefully" }

    it "validates consistency for cautious personality" do
      result = PersonalityService.validate_personality_consistency(
        "cautious", previous_responses, new_response
      )

      expect(result).to include(:consistent, :score)
      expect(result[:consistent]).to be_truthy
      expect(result[:score]).to be > 70
    end

    it "detects inconsistency" do
      inconsistent_response = "WE DEMAND IMMEDIATE ACTION AND WILL NOT TOLERATE ANY DELAYS!"

      result = PersonalityService.validate_personality_consistency(
        "cautious", previous_responses, inconsistent_response
      )

      expect(result[:consistent]).to be_falsy
      expect(result[:score]).to be < 50
    end
  end
end
