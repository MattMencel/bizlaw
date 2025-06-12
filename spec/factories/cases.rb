# frozen_string_literal: true

FactoryBot.define do
  factory :case do
    association :team
    association :created_by, factory: :user
    association :updated_by, factory: :user

    title { "Mitchell v. TechFlow Industries" }
    description { "Sexual harassment lawsuit involving workplace misconduct allegations" }
    reference_number { "CASE-#{SecureRandom.hex(4).upcase}" }
    status { :not_started }
    difficulty_level { :intermediate }
    case_type { :sexual_harassment }
    plaintiff_info { { "name" => "Sarah Mitchell", "position" => "Software Engineer" } }
    defendant_info { { "name" => "TechFlow Industries", "type" => "Corporation" } }
    legal_issues { ["Sexual harassment", "Hostile work environment", "Retaliation"] }

    # Create case teams after the case is created
    after(:create) do |case_instance|
      plaintiff_team = create(:team, name: "#{case_instance.title} - Plaintiff Team")
      defendant_team = create(:team, name: "#{case_instance.title} - Defendant Team")

      create(:case_team, case: case_instance, team: plaintiff_team, role: "plaintiff")
      create(:case_team, case: case_instance, team: defendant_team, role: "defendant")
    end

    trait :with_documents do
      transient do
        documents_count { 2 }
      end

      after(:create) do |case_instance, evaluator|
        create_list(:document, evaluator.documents_count, documentable: case_instance)
      end
    end

    trait :in_progress do
      status { :in_progress }
    end

    trait :submitted do
      status { :submitted }
    end

    trait :reviewed do
      status { :reviewed }
    end

    trait :completed do
      status { :completed }
    end

    trait :soft_deleted do
      deleted_at { Time.current }
    end

    trait :with_simulation do
      after(:create) do |case_instance|
        create(:simulation, case: case_instance)
      end
    end
  end
end
