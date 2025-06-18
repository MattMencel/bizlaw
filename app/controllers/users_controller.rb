# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!

  def impersonate
    user_to_impersonate = User.find(params[:id])
    authorize user_to_impersonate, :impersonate?

    session[:admin_user_id] = actual_user.id
    session[:impersonated_user_id] = user_to_impersonate.id
    session[:impersonation_full_permissions] = false

    # Force session to be saved before redirect
    session.commit!

    flash[:notice] = "You are now impersonating #{user_to_impersonate.full_name} in read-only mode."
    redirect_to dashboard_path
  end

  def stop_impersonation
    unless impersonating?
      flash[:alert] = "You are not currently impersonating anyone."
      redirect_to root_path
      return
    end

    admin_user = User.find(session[:admin_user_id])
    policy = UserPolicy.new(admin_user, admin_user)
    unless policy.stop_impersonation?
      raise Pundit::NotAuthorizedError
    end

    session.delete(:admin_user_id)
    session.delete(:impersonated_user_id)
    session.delete(:impersonation_full_permissions)

    flash[:notice] = "Stopped impersonating. You are now #{admin_user.full_name}."
    redirect_to dashboard_path
  end

  def enable_full_permissions
    unless impersonating?
      flash[:alert] = "You are not currently impersonating anyone."
      redirect_to dashboard_path
      return
    end

    admin_user = User.find(session[:admin_user_id])
    policy = UserPolicy.new(admin_user, admin_user)
    unless policy.enable_full_permissions?
      raise Pundit::NotAuthorizedError
    end

    session[:impersonation_full_permissions] = true
    flash[:notice] = "Full permissions enabled for testing purposes."
    redirect_back(fallback_location: dashboard_path)
  end

  def disable_full_permissions
    unless impersonating?
      flash[:alert] = "You are not currently impersonating anyone."
      redirect_to dashboard_path
      return
    end

    admin_user = User.find(session[:admin_user_id])
    policy = UserPolicy.new(admin_user, admin_user)
    unless policy.disable_full_permissions?
      raise Pundit::NotAuthorizedError
    end

    session[:impersonation_full_permissions] = false
    flash[:notice] = "Returned to read-only mode."
    redirect_back(fallback_location: dashboard_path)
  end
end
