# frozen_string_literal: true

FactoryBot.define do
  factory :case_team do
    association :case
    association :team
    role { :plaintiff }

    trait :plaintiff do
      role { :plaintiff }
    end

    trait :defendant do
      role { :defendant }
    end

    trait :with_case do
      association :case, factory: [:case, :sexual_harassment]
    end

    trait :with_team do
      association :team, :with_members
    end

    trait :complete_assignment do
      with_case
      with_team
    end

    # Factory for creating a complete case with both plaintiff and defendant teams
    factory :case_team_plaintiff, traits: [:plaintiff, :complete_assignment]
    factory :case_team_defendant, traits: [:defendant, :complete_assignment]

    # Helper factory for setting up a full case scenario
    factory :case_with_teams, class: 'Case' do
      transient do
        plaintiff_team { nil }
        defendant_team { nil }
      end

      title { 'Case with Teams' }
      description { 'A test case with plaintiff and defendant teams assigned' }
      case_type { :sexual_harassment }
      difficulty_level { :beginner }
      association :created_by, factory: :user, role: :instructor

      after(:create) do |case_record, evaluator|
        # Create plaintiff team if not provided
        plaintiff_team = evaluator.plaintiff_team || create(:team, name: 'Plaintiff Team')
        # Create defendant team if not provided
        defendant_team = evaluator.defendant_team || create(:team, name: 'Defendant Team')

        # Assign teams to case
        create(:case_team, case: case_record, team: plaintiff_team, role: :plaintiff)
        create(:case_team, case: case_record, team: defendant_team, role: :defendant)
      end
    end
  end
end
