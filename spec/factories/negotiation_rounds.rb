# frozen_string_literal: true

FactoryBot.define do
  factory :negotiation_round do
    association :simulation
    round_number { 1 }
    status { :pending }
    deadline { 2.days.from_now }
    started_at { nil }
    completed_at { nil }

    trait :active do
      status { :active }
      started_at { 1.hour.ago }
    end

    trait :plaintiff_submitted do
      status { :plaintiff_submitted }
      started_at { 2.hours.ago }
    end

    trait :defendant_submitted do
      status { :defendant_submitted }
      started_at { 2.hours.ago }
    end

    trait :both_submitted do
      status { :both_submitted }
      started_at { 2.hours.ago }
    end

    trait :completed do
      status { :completed }
      started_at { 1.day.ago }
      completed_at { 1.hour.ago }
    end

    trait :overdue do
      deadline { 1.hour.ago }
    end

    trait :round_2 do
      round_number { 2 }
    end

    trait :round_3 do
      round_number { 3 }
    end

    trait :final_round do
      round_number { 6 }
    end
  end
end
