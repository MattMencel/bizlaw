# frozen_string_literal: true

FactoryBot.define do
  factory :case do
    association :course
    association :created_by, factory: :user
    association :updated_by, factory: :user

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
      # Create case teams after the case is created
      after(:create) do |case_instance|
        # Create owners who are enrolled in the course
        plaintiff_owner = create(:user)
        defendant_owner = create(:user)

        create(:course_enrollment, user: plaintiff_owner, course: case_instance.course)
        create(:course_enrollment, user: defendant_owner, course: case_instance.course)

        plaintiff_team = create(:team,
          name: "#{case_instance.title} - Plaintiff Team",
          course: case_instance.course,
          owner: plaintiff_owner)
        defendant_team = create(:team,
          name: "#{case_instance.title} - Defendant Team",
          course: case_instance.course,
          owner: defendant_owner)

        create(:case_team, case: case_instance, team: plaintiff_team, role: "plaintiff")
        create(:case_team, case: case_instance, team: defendant_team, role: "defendant")
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
