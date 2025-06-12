# frozen_string_literal: true

class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [ :show, :edit, :update, :destroy, :assign_org_admin, :remove_org_admin ]

  def index
    authorize User
    @users = policy_scope(User).includes(:organization)

    # Apply sorting
    sort_column = params[:sort] || "first_name"
    sort_direction = params[:direction] || "asc"

    # Validate sort parameters
    valid_sort_columns = %w[first_name last_name email role created_at]
    sort_column = "first_name" unless valid_sort_columns.include?(sort_column)
    sort_direction = "asc" unless %w[asc desc].include?(sort_direction)

    case sort_column
    when "first_name", "last_name", "email", "role", "created_at"
      @users = @users.order("#{sort_column} #{sort_direction}")
    else
      @users = @users.order(:first_name, :last_name)
    end

    # Filter by search query if provided
    if params[:search].present?
      @users = @users.where(
        "LOWER(first_name) LIKE :query OR LOWER(last_name) LIKE :query OR LOWER(email) LIKE :query",
        query: "%#{params[:search].downcase}%"
      )
    end

    # Filter by role if provided
    if params[:role].present? && User.roles.key?(params[:role])
      @users = @users.where(role: params[:role])
    end

    # Filter by organization if provided
    if params[:organization_id].present?
      @users = @users.where(organization_id: params[:organization_id])
    end

    @users = @users.page(params[:page]).per(20)
  end

  def show
    authorize @user
    @teams_count = @user.teams.count
    @recent_teams = @user.teams.includes(:cases).order(created_at: :desc).limit(5)
  end

  def edit
    authorize @user
  end

  def update
    authorize @user
    if @user.update(user_params)
      redirect_to admin_user_path(@user),
                  notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @user
    if @user.teams.exists?
      redirect_to admin_users_path,
                  alert: "Cannot delete user with existing team memberships. Please remove from teams first."
    else
      @user.destroy
      redirect_to admin_users_path,
                  notice: "User was successfully deleted."
    end
  end

  def assign_org_admin
    authorize @user, :assign_org_admin?

    if @user.update(org_admin: true)
      redirect_back(fallback_location: admin_user_path(@user),
                    notice: "User successfully assigned as organization admin.")
    else
      redirect_back(fallback_location: admin_user_path(@user),
                    alert: "Failed to assign user as organization admin.")
    end
  end

  def remove_org_admin
    authorize @user, :remove_org_admin?

    if @user.update(org_admin: false)
      redirect_back(fallback_location: admin_user_path(@user),
                    notice: "Organization admin role removed from user.")
    else
      redirect_back(fallback_location: admin_user_path(@user),
                    alert: "Failed to remove organization admin role.")
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :role, :organization_id, :active, :org_admin)
  end
end
