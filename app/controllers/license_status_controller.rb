# frozen_string_literal: true

class LicenseStatusController < ApplicationController
  before_action :authenticate_user!

  def show
    @organization = current_user.organization
    @enforcement_service = LicenseEnforcementService.new(organization: @organization)

    if @organization
      @license = @organization.effective_license
      @usage_summary = @organization.usage_summary
      @warnings = @organization.license_warnings
    else
      @license = nil
      @usage_summary = {}
      @warnings = []
    end
  end

  def activate_license
    license_key = params[:license_key]&.strip

    if license_key.blank?
      flash[:alert] = "Please enter a license key"
      redirect_to license_status_path
      return
    end

    license = License.validate_license_key(license_key)

    if license.nil?
      flash[:alert] = "Invalid or expired license key"
      redirect_to license_status_path
      return
    end

    if license.organization.present?
      flash[:alert] = "This license is already in use by another organization"
      redirect_to license_status_path
      return
    end

    # Assign license to current organization
    if current_user.organization
      current_user.organization.update!(license: license)
      flash[:notice] = "License activated successfully!"
    else
      flash[:alert] = "You must belong to an organization to activate a license"
    end

    redirect_to license_status_path
  end

  def request_trial
    # Logic for requesting a trial license
    organization = current_user.organization

    if organization.nil?
      flash[:alert] = "You must belong to an organization to request a trial"
      redirect_to license_status_path
      return
    end

    if organization.license && !organization.license.license_type_free?
      flash[:alert] = "You already have an active license"
      redirect_to license_status_path
      return
    end

    # Create a 30-day trial license
    trial_license = License.generate_signed_license(
      organization_name: organization.name,
      contact_email: current_user.email,
      license_type: "starter",
      max_instructors: 2,
      max_students: 25,
      max_courses: 5,
      expires_at: 30.days.from_now.to_date,
      notes: "30-day trial license"
    )

    if trial_license.save
      organization.update!(license: trial_license)
      flash[:notice] = "Trial license activated! You have 30 days to evaluate the platform."
    else
      flash[:alert] = "Unable to create trial license. Please contact support."
    end

    redirect_to license_status_path
  end
end
