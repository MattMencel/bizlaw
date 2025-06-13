FactoryBot.define do
  factory :evidence_release do
    simulation { nil }
    document { nil }
    release_round { 1 }
    scheduled_release_at { "2025-06-12 21:59:03" }
    released_at { "2025-06-12 21:59:03" }
    release_conditions { "" }
    team_requested { false }
    requesting_team { nil }
    auto_release { false }
    evidence_type { "MyString" }
    impact_description { "MyText" }
  end
end
