# frozen_string_literal: true

FactoryBot.define do
  factory :client_feedback do
    transient do
      case_instance { nil }
    end
    
    simulation { case_instance ? create(:simulation, case: case_instance) : create(:simulation, case: create(:case, :with_teams)) }
    team { simulation.case.plaintiff_team }
    settlement_offer { nil }
    
    feedback_type { :offer_reaction }
    mood_level { :neutral }
    satisfaction_score { rand(40..80) }
    feedback_text { "Client reviewing the settlement position and considering next steps." }
    triggered_by_round { 1 }

    trait :positive do
      mood_level { :satisfied }
      satisfaction_score { rand(70..90) }
      feedback_text { "Client pleased with the strategic positioning and negotiation approach." }
    end

    trait :negative do
      mood_level { :unhappy }
      satisfaction_score { rand(20..40) }
      feedback_text { "Client concerned about the current negotiation strategy and positioning." }
    end

    trait :very_positive do
      mood_level { :very_satisfied }
      satisfaction_score { rand(85..100) }
      feedback_text { "Client extremely pleased with excellent strategic positioning and results." }
    end

    trait :very_negative do
      mood_level { :very_unhappy }
      satisfaction_score { rand(10..25) }
      feedback_text { "Client very disappointed with negotiation approach and concerned about outcome." }
    end

    trait :strategy_guidance do
      feedback_type { :strategy_guidance }
      feedback_text { "Consider adjusting negotiation strategy based on recent developments." }
    end

    trait :pressure_response do
      feedback_type { :pressure_response }
      feedback_text { "Client responding to external pressure and changing circumstances." }
    end

    trait :settlement_satisfaction do
      feedback_type { :settlement_satisfaction }
      feedback_text { "Client evaluating final settlement outcome and satisfaction level." }
    end
  end
end