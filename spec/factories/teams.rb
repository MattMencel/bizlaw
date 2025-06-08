# frozen_string_literal: true

FactoryBot.define do
  factory :team do
    name { Faker::Team.name }
    description { Faker::Lorem.paragraph }
    max_members { 5 }
    association :owner, factory: :user

    trait :with_members do
      transient do
        members_count { 2 }
      end

      after(:create) do |team, evaluator|
        create_list(:team_member, evaluator.members_count, team: team)
      end
    end

    trait :with_managers do
      transient do
        managers_count { 1 }
      end

      after(:create) do |team, evaluator|
        create_list(:team_member, evaluator.managers_count, team: team, role: "manager")
      end
    end

    trait :with_cases do
      transient do
        cases_count { 1 }
      end

      after(:create) do |team, evaluator|
        create_list(:case, evaluator.cases_count, team: team)
      end
    end

    trait :full do
      after(:create) do |team|
        create_list(:team_member, team.max_members, team: team)
      end
    end

    trait :soft_deleted do
      deleted_at { Time.current }
    end
  end
end
