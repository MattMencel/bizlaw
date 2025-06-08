# frozen_string_literal: true

FactoryBot.define do
  factory :case_type do
    sequence(:title) { |n| "Case Type #{n}" }
    description { "A detailed description of the case type" }
    difficulty_level { :intermediate }
    estimated_time { 60 } # minutes

    trait :with_documents do
      transient do
        documents_count { 2 }
      end

      after(:create) do |case_type, evaluator|
        create_list(:document, evaluator.documents_count, documentable: case_type)
      end
    end

    trait :with_cases do
      transient do
        cases_count { 2 }
      end

      after(:create) do |case_type, evaluator|
        create_list(:case, evaluator.cases_count, case_type: case_type)
      end
    end

    trait :beginner do
      difficulty_level { :beginner }
      estimated_time { 30 }
    end

    trait :advanced do
      difficulty_level { :advanced }
      estimated_time { 120 }
    end

    trait :soft_deleted do
      deleted_at { Time.current }
    end
  end
end
