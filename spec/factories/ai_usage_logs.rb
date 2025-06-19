# frozen_string_literal: true

FactoryBot.define do
  factory :ai_usage_log do
    model { "gemini-2.0-flash-lite" }
    cost { 0.001 }
    response_time_ms { 250 }
    tokens_used { 150 }
    request_type { "settlement_feedback" }
    error_occurred { false }
    metadata { {} }

    trait :high_cost do
      cost { 0.01 }
    end

    trait :slow_response do
      response_time_ms { 2000 }
    end

    trait :failed_request do
      error_occurred { true }
      cost { 0 }
      response_time_ms { 5000 }
    end

    trait :negotiation_analysis do
      request_type { "negotiation_analysis" }
      tokens_used { 200 }
      cost { 0.002 }
    end

    trait :gap_analysis do
      request_type { "gap_analysis" }
      tokens_used { 180 }
      cost { 0.0015 }
    end

    trait :yesterday do
      created_at { 1.day.ago }
    end

    trait :last_hour do
      created_at { 30.minutes.ago }
    end
  end
end
