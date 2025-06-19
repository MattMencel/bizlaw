# frozen_string_literal: true

FactoryBot.define do
  factory :ai_usage_alert do
    alert_type { "budget_warning" }
    threshold_value { 5.0 }
    current_value { 4.5 }
    status { "active" }
    message { "Daily budget approaching limit" }
    metadata { {} }

    trait :budget_exceeded do
      alert_type { "budget_exceeded" }
      current_value { 5.5 }
      message { "Daily budget exceeded" }
    end

    trait :rate_limit_warning do
      alert_type { "rate_limit_warning" }
      threshold_value { 1000 }
      current_value { 950 }
      message { "Approaching hourly rate limit" }
    end

    trait :rate_limit_exceeded do
      alert_type { "rate_limit_exceeded" }
      threshold_value { 1000 }
      current_value { 1001 }
      message { "Hourly rate limit exceeded" }
    end

    trait :acknowledged do
      status { "acknowledged" }
      acknowledged_at { 1.hour.ago }
      acknowledged_by { "admin@example.com" }
    end

    trait :resolved do
      status { "resolved" }
      resolved_at { 30.minutes.ago }
      resolved_by { "admin@example.com" }
    end

    trait :high_latency do
      alert_type { "high_latency" }
      threshold_value { 1000 }
      current_value { 2500 }
      message { "API response times are high" }
    end
  end
end
