# frozen_string_literal: true

FactoryBot.define do
  factory :case_type do
    sequence(:title) { |n| "Case Type #{n}" }
    description { "A detailed description of the case type" }

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
  end
end
