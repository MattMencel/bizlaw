# frozen_string_literal: true

FactoryBot.define do
  factory :case do
    association :team
    association :created_by, factory: :user
    association :updated_by, factory: :user

    sequence(:title) { |n| "Case #{n}" }
    description { "A detailed case description" }
    case_type { :sexual_harassment }
    difficulty_level { :intermediate }
    status { :not_started }
    sequence(:reference_number) { |n| "REF-#{n}" }
    plaintiff_info { { "name" => "John Doe", "role" => "Employee" } }
    defendant_info { { "name" => "ABC Corp", "role" => "Employer" } }
    legal_issues { ["Sexual harassment", "Hostile work environment"] }

    trait :with_documents do
      transient do
        documents_count { 2 }
      end

      after(:create) do |case_instance, evaluator|
        create_list(:document, evaluator.documents_count, documentable: case_instance)
      end
    end

    trait :in_progress do
      status { :in_progress }
    end

    trait :submitted do
      status { :submitted }
    end

    trait :reviewed do
      status { :reviewed }
    end

    trait :completed do
      status { :completed }
    end

    trait :soft_deleted do
      deleted_at { Time.current }
    end
  end
end
