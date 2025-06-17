FactoryBot.define do
  factory :course_enrollment do
    association :user
    association :course
    enrolled_at { Time.current }
    status { "active" }
  end
end
