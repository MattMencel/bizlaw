# frozen_string_literal: true

FactoryBot.define do
  factory :personality_consistency_tracker do
    association :case
    personality_type { "aggressive" }
    response_history { ["Response 1", "Response 2"] }
    consistency_score { 75 }

    trait :high_consistency do
      consistency_score { 85 }
      response_history do
        [
          "We demand a higher settlement amount.",
          "This offer is completely unacceptable.",
          "We insist on a more reasonable proposal."
        ]
      end
    end

    trait :low_consistency do
      consistency_score { 35 }
      response_history do
        [
          "We demand immediate action!",
          "Perhaps we should consider this carefully.",
          "I feel quite emotional about this situation."
        ]
      end
    end

    trait :cautious_personality do
      personality_type { "cautious" }
      response_history do
        [
          "We need to carefully evaluate this offer.",
          "Let us consider all aspects thoroughly.",
          "A prudent approach would be advisable."
        ]
      end
    end

    trait :emotional_personality do
      personality_type { "emotional" }
      response_history do
        [
          "This situation makes me feel very concerned.",
          "I am emotionally invested in this outcome.",
          "These developments are quite frustrating."
        ]
      end
    end
  end
end
