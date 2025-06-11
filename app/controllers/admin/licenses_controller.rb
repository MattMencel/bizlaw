# frozen_string_literal: true

class Admin::LicensesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_license, only: [ :show, :edit, :update, :destroy, :activate, :deactivate ]

  def index
    @licenses = License.includes(:organization)
                      .order(created_at: :desc)
                      .page(params[:page])

    if params[:search].present?
      @licenses = @licenses.where(
        "organization_name ILIKE ? OR contact_email ILIKE ? OR license_key ILIKE ?",
        "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%"
      )
    end

    if params[:license_type].present?
      @licenses = @licenses.where(license_type: params[:license_type])
    end

    if params[:status].present?
      case params[:status]
      when "active"
        @licenses = @licenses.where(active: true)
      when "expired"
        @licenses = @licenses.expired
      when "expiring_soon"
        @licenses = @licenses.expiring_soon
      end
    end
  end

  def show
    @usage_stats = @license.usage_stats
  end

  def new
    @license = License.new
  end

  def create
    @license = License.generate_signed_license(license_params)

    if @license.save
      redirect_to admin_license_path(@license), notice: "License was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @license.update(license_params.except(:license_key))
      # Regenerate signature after update
      @license.update!(signature: License.sign_license_data(@license.attributes_for_signing))
      redirect_to admin_license_path(@license), notice: "License was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @license.destroy
    redirect_to admin_licenses_path, notice: "License was successfully deleted."
  end

  def activate
    @license.update!(active: true)
    redirect_to admin_license_path(@license), notice: "License activated successfully."
  end

  def deactivate
    @license.update!(active: false)
    redirect_to admin_license_path(@license), notice: "License deactivated successfully."
  end

  def validate_key
    license = License.validate_license_key(params[:license_key])

    if license
      render json: {
        valid: true,
        license: {
          organization_name: license.organization_name,
          license_type: license.license_type,
          expires_at: license.expires_at,
          max_instructors: license.max_instructors,
          max_students: license.max_students,
          max_courses: license.max_courses
        }
      }
    else
      render json: { valid: false, error: "Invalid or expired license key" }
    end
  end

  private

  def set_license
    @license = License.find(params[:id])
  end

  def license_params
    params.require(:license).permit(
      :organization_name, :contact_email, :license_type,
      :max_instructors, :max_students, :max_courses,
      :expires_at, :notes, features: {}
    )
  end

  def ensure_admin!
    redirect_to root_path, alert: "Access denied." unless current_user.admin?
  end
end
