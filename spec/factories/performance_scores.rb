# frozen_string_literal: true

FactoryBot.define do
  factory :performance_score do
    simulation
    team
    user

    score_type { "individual" }
    total_score { rand(60..95) }
    settlement_quality_score { rand(20..40) }
    legal_strategy_score { rand(18..30) }
    collaboration_score { rand(12..20) }
    efficiency_score { rand(6..10) }
    speed_bonus { rand(0..10) }
    creative_terms_score { rand(0..10) }
    scored_at { Time.current }

    # Automatically calculate score_breakdown
    after(:build) do |score|
      score.score_breakdown = {
        "settlement_quality" => {
          "score" => score.settlement_quality_score || 0,
          "max_points" => 40,
          "weight" => "40%"
        },
        "legal_strategy" => {
          "score" => score.legal_strategy_score || 0,
          "max_points" => 30,
          "weight" => "30%"
        },
        "collaboration" => {
          "score" => score.collaboration_score || 0,
          "max_points" => 20,
          "weight" => "20%"
        },
        "efficiency" => {
          "score" => score.efficiency_score || 0,
          "max_points" => 10,
          "weight" => "10%"
        },
        "speed_bonus" => {
          "score" => score.speed_bonus || 0,
          "max_points" => 10,
          "weight" => "Bonus"
        },
        "creative_terms" => {
          "score" => score.creative_terms_score || 0,
          "max_points" => 10,
          "weight" => "Bonus"
        }
      }
    end

    trait :team_score do
      score_type { "team" }
      user { nil }
    end

    trait :individual_score do
      score_type { "individual" }
      association :user
    end

    trait :high_performer do
      total_score { rand(85..100) }
      settlement_quality_score { rand(32..40) }
      legal_strategy_score { rand(24..30) }
      collaboration_score { rand(16..20) }
      efficiency_score { rand(8..10) }
      speed_bonus { rand(5..10) }
      creative_terms_score { rand(3..10) }
    end

    trait :low_performer do
      total_score { rand(40..65) }
      settlement_quality_score { rand(10..25) }
      legal_strategy_score { rand(8..20) }
      collaboration_score { rand(5..15) }
      efficiency_score { rand(2..8) }
      speed_bonus { 0 }
      creative_terms_score { 0 }
    end

    trait :average_performer do
      total_score { rand(70..84) }
      settlement_quality_score { rand(26..35) }
      legal_strategy_score { rand(20..26) }
      collaboration_score { rand(14..18) }
      efficiency_score { rand(6..9) }
      speed_bonus { rand(0..5) }
      creative_terms_score { rand(0..5) }
    end

    trait :with_instructor_adjustment do
      instructor_adjustment { rand(-5..10) }
      adjustment_reason { "Manual adjustment for exceptional circumstances" }
      adjusted_by { association(:user, :instructor) }
      adjusted_at { Time.current }
    end

    trait :recent do
      scored_at { rand(1..3).hours.ago }
    end

    trait :historical do
      scored_at { rand(1..30).days.ago }
    end
  end
end
