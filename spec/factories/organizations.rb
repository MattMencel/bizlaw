FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Test University #{n}" }
    sequence(:domain) { |n| "test#{n}.edu" }
    sequence(:slug) { |n| "test-university-#{n}" }
    active { true }
    direct_assignment_enabled { true }
    created_at { Time.current }
    updated_at { Time.current }
  end
end
