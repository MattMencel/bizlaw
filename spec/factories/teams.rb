# frozen_string_literal: true

FactoryBot.define do
  factory :team do
    name { Faker::Team.name }
    description { Faker::Lorem.paragraph }
    max_members { 5 }
    role { "plaintiff" }

    # Teams hang off a simulation, not a course (72001a1). `course:` is a
    # convenience for specs that only care which course the team ends up in --
    # it builds the intervening case and simulation.
    transient do
      course { nil }
    end

    simulation { course ? create(:simulation, case: create(:case, course: course)) : create(:simulation) }

    # Team#owner_must_be_enrolled_in_course runs on create, so the owner has to
    # be valid before the record is saved. The course instructor always is.
    owner { simulation.case.course.instructor }

    before(:create) do |team|
      # A student owner must be enrolled before validation, not after.
      if team.owner&.student? && team.simulation&.case&.course && !team.simulation.case.course.course_enrollments.exists?(user: team.owner)
        create(:course_enrollment, user: team.owner, course: team.simulation.case.course, status: "active")
      end
    end

    trait :with_members do
      transient do
        members_count { 2 }
      end

      after(:create) do |team, evaluator|
        create_list(:team_member, evaluator.members_count, team: team)
      end
    end

    trait :with_managers do
      transient do
        managers_count { 1 }
      end

      after(:create) do |team, evaluator|
        create_list(:team_member, evaluator.managers_count, team: team, role: "manager")
      end
    end

    trait :defendant do
      role { "defendant" }
    end

    trait :plaintiff do
      role { "plaintiff" }
    end

    trait :full do
      after(:create) do |team|
        create_list(:team_member, team.max_members, team: team)
      end
    end

    trait :soft_deleted do
      deleted_at { Time.current }
    end
  end
end
