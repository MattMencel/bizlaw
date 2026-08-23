# frozen_string_literal: true

FactoryBot.define do
  factory :case do
    association :course
    # Simulation#create_default_teams makes created_by the owner of both default
    # teams, and Team#owner_must_be_enrolled_in_course requires an owner who can
    # manage the course. Default to the course instructor so the association is
    # valid; pass created_by explicitly to exercise the invalid case.
    created_by { course.instructor }
    updated_by { created_by }

    sequence(:title) { |n| "Mitchell v. TechFlow Industries #{n}" }
    description { "Sexual harassment lawsuit involving workplace misconduct allegations" }
    sequence(:reference_number) { |n| "CASE-#{n.to_s.rjust(4, "0")}" }
    status { :not_started }
    difficulty_level { :intermediate }
    case_type { :sexual_harassment }
    plaintiff_info { {"name" => "Sarah Mitchell", "position" => "Software Engineer"} }
    defendant_info { {"name" => "TechFlow Industries", "type" => "Corporation"} }
    legal_issues { ["Sexual harassment", "Hostile work environment", "Retaliation"] }

    trait :with_teams do
      # Teams reach a case through a simulation, and a simulation creates its
      # own plaintiff and defendant teams on create.
      after(:create) do |case_instance|
        create(:simulation, case: case_instance)
      end
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
