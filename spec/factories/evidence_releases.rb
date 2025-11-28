FactoryBot.define do
  factory :evidence_release do
    association :simulation
    association :document
    release_round { 1 }
    scheduled_release_at { 1.week.from_now }
    released_at { nil }
    release_conditions { {} }
    team_requested { false }
    requesting_team { nil }
    auto_release { true }
    evidence_type { "witness_statement" }
    impact_description { "Key witness testimony that may impact the case outcome" }

    trait :released do
      released_at { 1.day.ago }
    end

    trait :team_requested do
      team_requested { true }
      auto_release { false }
      association :requesting_team, factory: :team
      release_conditions { {"request_justification" => "Critical evidence needed for defense", "requested_at" => 2.days.ago} }
    end

    trait :approved do
      team_requested { true }
      auto_release { false }
      association :requesting_team, factory: :team
      release_conditions { {"approved_by" => "instructor@example.com", "approved_at" => 1.day.ago} }
    end

    trait :overdue do
      scheduled_release_at { 2.days.ago }
    end

    trait :expert_report do
      evidence_type { "expert_report" }
      impact_description { "Expert analysis on damages and liability" }
    end

    trait :company_document do
      evidence_type { "company_document" }
      impact_description { "Internal company policy document" }
    end

    trait :financial_document do
      evidence_type { "financial_document" }
      impact_description { "Financial records showing company status" }
    end

    trait :round_2 do
      release_round { 2 }
      scheduled_release_at { 2.weeks.from_now }
    end

    trait :round_3 do
      release_round { 3 }
      scheduled_release_at { 3.weeks.from_now }
    end
  end
end
