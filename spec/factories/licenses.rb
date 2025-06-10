# frozen_string_literal: true

FactoryBot.define do
  factory :license do
    sequence(:organization_name) { |n| "Organization #{n}" }
    sequence(:contact_email) { |n| "contact#{n}@example.com" }
    license_type { 'free' }
    max_instructors { 1 }
    max_students { 3 }
    max_courses { 1 }
    expires_at { nil }
    active { true }

    after(:build) do |license|
      # Ensure license has all required attributes before signing
      license.license_key ||= "#{license.license_type.upcase}-#{SecureRandom.hex(4).upcase}-#{SecureRandom.hex(4).upcase}"
      license.signature = License.sign_license_data(license.attributes_for_signing)
    end

    trait :starter do
      license_type { 'starter' }
      max_instructors { 2 }
      max_students { 25 }
      max_courses { 5 }
      expires_at { 1.year.from_now.to_date }
    end

    trait :professional do
      license_type { 'professional' }
      max_instructors { 5 }
      max_students { 100 }
      max_courses { 20 }
      expires_at { 1.year.from_now.to_date }
    end

    trait :enterprise do
      license_type { 'enterprise' }
      max_instructors { 50 }
      max_students { 1000 }
      max_courses { 100 }
      expires_at { 1.year.from_now.to_date }
    end

    trait :expired do
      expires_at { 1.month.ago.to_date }
    end

    trait :expiring_soon do
      expires_at { 15.days.from_now.to_date }
    end

    trait :inactive do
      active { false }
    end

    trait :trial do
      starter
      expires_at { 30.days.from_now.to_date }
      features { { 'trial' => true } }
    end
  end
end
