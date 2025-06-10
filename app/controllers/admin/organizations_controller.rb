# frozen_string_literal: true

class Admin::OrganizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization, only: [:show, :edit, :update, :destroy, :activate, :deactivate]

  def index
    authorize Organization
    @organizations = policy_scope(Organization).includes(:license, :users, :courses)
                                              .order(:name)
                                              .page(params[:page])
                                              .per(20)

    # Filter by search query if provided
    if params[:search].present?
      @organizations = @organizations.search_by_name(params[:search])
    end

    # Filter by status if provided
    case params[:status]
    when 'active'
      @organizations = @organizations.active
    when 'inactive'
      @organizations = @organizations.where(active: false)
    end
  end

  def show
    authorize @organization
    @users_count = @organization.users.count
    @courses_count = @organization.courses.count
    @recent_users = @organization.users.order(created_at: :desc).limit(10)
    @recent_courses = @organization.courses.order(created_at: :desc).limit(10)
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
                  notice: 'Organization was successfully created.'
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
                  notice: 'Organization was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @organization
    if @organization.users.exists?
      redirect_to admin_organizations_path,
                  alert: 'Cannot delete organization with existing users. Please transfer or delete users first.'
    else
      @organization.destroy
      redirect_to admin_organizations_path,
                  notice: 'Organization was successfully deleted.'
    end
  end

  def activate
    authorize @organization
    @organization.update!(active: true)
    redirect_to admin_organization_path(@organization),
                notice: 'Organization activated successfully.'
  end

  def deactivate
    authorize @organization
    @organization.update!(active: false)
    redirect_to admin_organization_path(@organization),
                notice: 'Organization deactivated successfully.'
  end

  private

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def organization_params
    params.require(:organization).permit(:name, :domain, :slug, :active, :license_id)
  end
end
