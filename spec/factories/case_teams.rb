# frozen_string_literal: true

FactoryBot.define do
  factory :case_team do
    association :case
    association :team
    role { "plaintiff" }

    trait :plaintiff do
      role { "plaintiff" }
    end

    trait :defendant do
      role { "defendant" }
    end
  end
end
