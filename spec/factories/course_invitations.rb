FactoryBot.define do
  factory :course_invitation do
    course { nil }
    token { "MyString" }
    expires_at { "2025-06-08 22:28:36" }
    max_uses { 1 }
    current_uses { 1 }
    active { false }
  end
end
