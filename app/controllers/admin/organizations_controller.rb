# frozen_string_literal: true

class Admin::OrganizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization, only: [ :show, :edit, :update, :destroy, :activate, :deactivate ]

  def index
    authorize Organization
    @organizations = policy_scope(Organization)

    # Apply sorting
    sort_column = params[:sort] || "name"
    sort_direction = params[:direction] || "asc"

    # Validate sort parameters
    valid_sort_columns = %w[name domain created_at]
    sort_column = "name" unless valid_sort_columns.include?(sort_column)
    sort_direction = "asc" unless %w[asc desc].include?(sort_direction)

    @organizations = @organizations.order("#{sort_column} #{sort_direction}")

    # Filter by search query if provided
    if params[:search].present?
      @organizations = @organizations.search_by_name(params[:search])
    end

    # Filter by status if provided
    case params[:status]
    when "active"
      @organizations = @organizations.active
    when "inactive"
      @organizations = @organizations.where(active: false)
    end

    @organizations = @organizations.page(params[:page]).per(20)
  end

  def show
    authorize @organization
    @users_count = @organization.users_count
    @courses_count = @organization.courses_count
    @recent_users = @organization.users.order(created_at: :desc).limit(10)
    @recent_courses = @organization.courses.includes(:instructor).order(created_at: :desc).limit(10)
  end

  def new
    @organization = Organization.new
    authorize @organization
  end

  def create
    @organization = Organization.new(organization_params)
    authorize @organization

    if @organization.save
      redirect_to admin_organization_path(@organization),
                  notice: "Organization was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @organization
  end

  def update
    authorize @organization
    if @organization.update(organization_params)
      redirect_to admin_organization_path(@organization),
                  notice: "Organization was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @organization
    if @organization.users.exists?
      redirect_to admin_organizations_path,
                  alert: "Cannot delete organization with existing users. Please transfer or delete users first."
    else
      @organization.destroy
      redirect_to admin_organizations_path,
                  notice: "Organization was successfully deleted."
    end
  end

  def activate
    authorize @organization
    @organization.update!(active: true)
    redirect_to admin_organization_path(@organization),
                notice: "Organization activated successfully."
  end

  def deactivate
    authorize @organization
    @organization.update!(active: false)
    redirect_to admin_organization_path(@organization),
                notice: "Organization deactivated successfully."
  end

  private

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def organization_params
    params.require(:organization).permit(:name, :domain, :slug, :active, :license_id, :direct_assignment_enabled)
  end
end
