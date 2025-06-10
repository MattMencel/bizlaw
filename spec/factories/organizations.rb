FactoryBot.define do
  factory :organization do
    name { "Test University" }
    domain { "test.edu" }
    slug { "test-university" }
    active { true }
    created_at { Time.current }
    updated_at { Time.current }
  end
end
