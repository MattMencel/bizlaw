# frozen_string_literal: true

FactoryBot.define do
  factory :jwt_denylist do
    jti { SecureRandom.uuid }
    exp { 1.hour.from_now }

    trait :expired do
      exp { 1.hour.ago }
    end

    trait :far_future do
      exp { 1.year.from_now }
    end

    trait :recently_expired do
      exp { 5.minutes.ago }
    end

    trait :expiring_soon do
      exp { 5.minutes.from_now }
    end

    # Factory for testing bulk operations
    factory :jwt_denylist_batch, class: 'Array' do
      transient do
        count { 5 }
        base_jti { 'batch-token' }
        exp_range { (1.hour.ago..1.hour.from_now) }
      end

      initialize_with do
        (1..count).map do |i|
          create(:jwt_denylist,
            jti: "#{base_jti}-#{i}",
            exp: exp_range.min + (exp_range.size * i / count)
          )
        end
      end
    end

    # Factory for testing cleanup scenarios
    factory :jwt_denylist_cleanup_scenario, class: 'Hash' do
      transient do
        expired_count { 3 }
        active_count { 2 }
      end

      initialize_with do
        expired_tokens = create_list(:jwt_denylist, expired_count, :expired)
        active_tokens = create_list(:jwt_denylist, active_count)

        {
          expired: expired_tokens,
          active: active_tokens,
          total_count: expired_count + active_count,
          expired_count: expired_count,
          active_count: active_count
        }
      end
    end
  end
end
