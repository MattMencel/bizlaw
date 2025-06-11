FactoryBot.define do
  factory :term do
    term_name { "MyString" }
    academic_year { 1 }
    slug { "MyString" }
    start_date { "2025-06-10" }
    end_date { "2025-06-10" }
    description { "MyText" }
    organization { nil }
    active { false }
  end
end
