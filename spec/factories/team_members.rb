# frozen_string_literal: true

FactoryBot.define do
  factory :team_member do
    association :team
    association :user
    role { :member }

    trait :manager do
      role { :manager }
    end

    trait :with_documents do
      transient do
        documents_count { 2 }
      end

      after(:create) do |team_member, evaluator|
        create_list(:document, evaluator.documents_count, team_member: team_member)
      end
    end

    trait :soft_deleted do
      deleted_at { Time.current }
    end
  end
end
