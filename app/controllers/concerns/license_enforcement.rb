# frozen_string_literal: true

module LicenseEnforcement
  extend ActiveSupport::Concern

  included do
    before_action :check_license_status, unless: :skip_license_check?
    helper_method :license_enforcement_service, :show_license_warning?
  end

  private

  def check_license_status
    return unless current_user&.organization
    return if license_enforcement_service.grace_period_active?

    case license_enforcement_service.license_status
    when "expired"
      handle_expired_license
    when "over_limits"
      handle_over_limits unless action_name.in?([ "show", "index" ])
    end
  end

  def handle_expired_license
    flash.now[:alert] = "Your license has expired. Some features may be limited. Please renew your license."

    # Allow read-only operations during grace period
    unless action_name.in?([ "show", "index" ]) || license_enforcement_service.grace_period_active?
      redirect_to license_status_path, alert: "License expired. Please renew to continue using the platform."
    end
  end

  def handle_over_limits
    warnings = license_enforcement_service.warnings
    if warnings.any?
      flash.now[:warning] = "License limits exceeded: #{warnings.join(', ')}"
    end
  end

  def license_enforcement_service
    @license_enforcement_service ||= LicenseEnforcementService.new(
      organization: current_user&.organization,
      user: current_user
    )
  end

  def show_license_warning?
    return false unless current_user&.organization

    license_enforcement_service.should_show_upgrade_prompt?
  end

  def skip_license_check?
    # Skip license checks for certain controllers/actions
    controller_name.in?([ "license_status", "health", "home" ]) ||
      (controller_name == "users" && action_name.in?([ "show", "edit", "update" ]))
  end

  def require_feature!(feature_name)
    license_enforcement_service.enforce_feature_access!(feature_name)
  rescue LicenseEnforcementService::FeatureNotLicensed => e
    if request.format.json?
      render json: { error: e.message }, status: :forbidden
    else
      redirect_to license_status_path, alert: e.message
    end
  end

  def check_user_creation_limit!(role)
    license_enforcement_service.enforce_user_limit!(role)
  rescue LicenseEnforcementService::LicenseLimitExceeded => e
    if request.format.json?
      render json: { error: e.message }, status: :forbidden
    else
      redirect_back(fallback_location: root_path, alert: e.message)
    end
  end

  def check_course_creation_limit!
    license_enforcement_service.enforce_course_limit!
  rescue LicenseEnforcementService::LicenseLimitExceeded => e
    if request.format.json?
      render json: { error: e.message }, status: :forbidden
    else
      redirect_back(fallback_location: root_path, alert: e.message)
    end
  end
end
