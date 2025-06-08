# frozen_string_literal: true

FactoryBot.define do
  factory :case do
    association :team
    association :case_type
    status { :not_started }

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
