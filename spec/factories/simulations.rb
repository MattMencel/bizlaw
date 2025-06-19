# frozen_string_literal: true

FactoryBot.define do
  factory :simulation do
    association :case
    start_date { 1.day.from_now }
    end_date { nil }
    total_rounds { 6 }
    current_round { 1 }
    status { :setup }
    plaintiff_min_acceptable { 150000 }
    plaintiff_ideal { 300000 }
    defendant_max_acceptable { 250000 }
    defendant_ideal { 75000 }
    pressure_escalation_rate { :moderate }
    simulation_config { {auto_events: true, scoring_enabled: true} }
    auto_events_enabled { true }
    argument_quality_required { true }

    trait :active do
      status { :active }
      start_date { 1.hour.ago }
    end

    trait :completed do
      status { :completed }
      start_date { 1.week.ago }
      end_date { 1.day.ago }
      current_round { 6 }
    end

    trait :arbitration do
      status { :arbitration }
      start_date { 1.week.ago }
      end_date { 1.day.ago }
      current_round { 6 }
    end

    trait :high_pressure do
      pressure_escalation_rate { :high }
    end

    trait :low_pressure do
      pressure_escalation_rate { :low }
    end
  end
end
