# frozen_string_literal: true

FactoryBot.define do
  factory :invitation do
    email { Faker::Internet.email }
    role { 'student' }
    association :invited_by, factory: :user, strategy: :create
    association :organization
    token { SecureRandom.urlsafe_base64(32) }
    status { 'pending' }
    expires_at { 7.days.from_now }
    shareable { false }
    org_admin { false }

    before(:create) do |invitation|
      # Ensure invited_by has permission to send invitations
      invitation.invited_by.update(role: :admin) unless invitation.invited_by.admin?
    end

    trait :for_instructor do
      role { 'instructor' }
    end

    trait :for_admin do
      role { 'admin' }
      organization { nil }
    end

    trait :org_admin do
      role { 'instructor' }
      org_admin { true }
    end

    trait :shareable do
      shareable { true }
      email { nil }
    end

    trait :expired do
      expires_at { 1.day.ago }
      status { 'expired' }
    end

    trait :accepted do
      status { 'accepted' }
      accepted_at { Time.current }
    end

    trait :revoked do
      status { 'revoked' }
    end

    trait :deleted do
      deleted_at { Time.current }
      active { false }
    end
  end
end