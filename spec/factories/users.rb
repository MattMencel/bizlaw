# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    first_name { "Test" }
    last_name { "User" }
    password { "password123" }
    password_confirmation { "password123" }
    role { :student }
    roles { ["student"] }

    trait :student do
      role { :student }
      roles { ["student"] }
    end

    trait :instructor do
      role { :instructor }
      roles { ["instructor"] }
    end

    trait :admin do
      role { :admin }
      roles { ["admin"] }
    end

    trait :org_admin do
      role { :instructor }
      roles { ["instructor", "org_admin"] }
    end

    trait :with_teams do
      transient do
        teams_count { 2 }
      end

      after(:create) do |user, evaluator|
        create_list(:team_member, evaluator.teams_count, user: user)
      end
    end

    trait :with_owned_teams do
      transient do
        owned_teams_count { 2 }
      end

      after(:create) do |user, evaluator|
        create_list(:team, evaluator.owned_teams_count, owner: user)
      end
    end

    trait :with_cases do
      transient do
        cases_count { 2 }
      end

      after(:create) do |user, evaluator|
        create_list(:case, evaluator.cases_count, created_by: user, updated_by: user)
      end
    end

    trait :with_documents do
      transient do
        documents_count { 2 }
      end

      after(:create) do |user, evaluator|
        create_list(:document, evaluator.documents_count, documentable: user)
      end
    end

    trait :soft_deleted do
      deleted_at { Time.current }
    end

    trait :confirmed do
      confirmed_at { Time.current }
    end

    trait :with_google_oauth do
      provider { "google_oauth2" }
      uid { "123456789" }
      oauth_token { "mock_token" }
      oauth_refresh_token { "mock_refresh_token" }
      oauth_expires_at { 1.hour.from_now }
    end
  end
end
