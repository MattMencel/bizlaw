FactoryBot.define do
  factory :course_invitation do
    association :course
    expires_at { 1.week.from_now }
    max_uses { nil }
    current_uses { 0 }
    active { true }
  end
end
