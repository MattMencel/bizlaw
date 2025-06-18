FactoryBot.define do
  factory :course do
    title { "Business Law 101" }
    description { "Introduction to Business Law" }
    association :instructor, factory: [ :user, :instructor ]
    association :organization
    course_code { "BL101" }
    semester { "Fall" }
    year { Date.current.year }
    start_date { Date.current.beginning_of_year }
    end_date { Date.current.end_of_year }
    active { true }
    created_at { Time.current }
    updated_at { Time.current }
  end
end
