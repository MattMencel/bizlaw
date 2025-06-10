# frozen_string_literal: true

class LicenseEnforcementService
  include ActiveModel::Model

  attr_accessor :organization, :user

  def initialize(organization: nil, user: nil)
    @organization = organization || user&.organization
    @user = user
  end

  def can_add_user?(role)
    return true if skip_enforcement?
    return true unless organization
    return true if grace_period_active?

    organization.can_add_user?(role)
  end

  def can_add_course?
    return true if skip_enforcement?
    return true unless organization
    return true if grace_period_active?

    organization.can_add_course?
  end

  def can_access_feature?(feature_name)
    return true if skip_enforcement?
    return true unless organization

    organization.feature_enabled?(feature_name)
  end

  def enforce_user_limit!(role)
    return true if can_add_user?(role)

    raise LicenseLimitExceeded.new(
      "Cannot add #{role}. License limit reached. " \
      "Current: #{organization.usage_summary[role.to_sym][:count]}, " \
      "Limit: #{organization.usage_summary[role.to_sym][:limit]}"
    )
  end

  def enforce_course_limit!
    return true if can_add_course?

    usage = organization.usage_summary
    raise LicenseLimitExceeded.new(
      "Cannot add course. License limit reached. " \
      "Current: #{usage[:courses][:count]}, " \
      "Limit: #{usage[:courses][:limit]}"
    )
  end

  def enforce_feature_access!(feature_name)
    return true if can_access_feature?(feature_name)

    raise FeatureNotLicensed.new(
      "Feature '#{feature_name}' is not available in your current license plan. " \
      "Upgrade your license to access this feature."
    )
  end

  def license_status
    return 'no_organization' unless organization

    organization.license_status
  end

  def warnings
    return [] unless organization

    organization.license_warnings
  end

  def should_show_upgrade_prompt?
    case license_status
    when 'expired', 'over_limits', 'expiring_soon'
      true
    else
      false
    end
  end

  def upgrade_message
    case license_status
    when 'expired'
      "Your license has expired. Please renew to continue using all features."
    when 'over_limits'
      "You've exceeded your license limits. Please upgrade to add more users or courses."
    when 'expiring_soon'
      "Your license expires soon. Please renew to avoid service interruption."
    else
      "Upgrade your license to unlock more features and capacity."
    end
  end

  def grace_period_active?
    return false unless organization&.license

    # Allow 30-day grace period for expired licenses
    license = organization.license
    return false unless license.expired?

    grace_period_end = license.expires_at + 30.days
    Date.current <= grace_period_end
  end

  def days_remaining_in_grace_period
    return 0 unless grace_period_active?

    license = organization.license
    grace_period_end = license.expires_at + 30.days
    (grace_period_end - Date.current).to_i
  end

  private

  def skip_enforcement?
    Rails.application.config.skip_license_enforcement
  end

  class LicenseLimitExceeded < StandardError; end
  class FeatureNotLicensed < StandardError; end
end
