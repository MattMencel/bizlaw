class ApplicationController < ActionController::Base
  include ErrorHandler
  include Pundit::Authorization

  # Disable CSRF tokens for API requests
  protect_from_forgery unless: -> { request.format.json? }

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!

  # Pundit error handling
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || cases_path
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  # Impersonation helper methods
  def current_user
    @current_user ||= if impersonating?
      User.find(session[:impersonated_user_id])
    else
      super
    end
  end

  def actual_user
    if impersonating?
      @actual_user ||= User.find(session[:admin_user_id])
    else
      current_user
    end
  end

  def impersonating?
    session[:admin_user_id].present? && session[:impersonated_user_id].present?
  end

  def read_only_mode?
    impersonating? && !session[:impersonation_full_permissions]
  end

  def impersonation_full_permissions?
    impersonating? && session[:impersonation_full_permissions] == true
  end

  helper_method :current_user, :actual_user, :impersonating?, :read_only_mode?, :impersonation_full_permissions?

  private

  def user_not_authorized
    if request.format.json?
      render json: {error: "You are not authorized to perform this action"}, status: :forbidden
    else
      flash[:alert] = "You are not authorized to perform this action."
      redirect_to(request.referrer || root_path)
    end
  end
end
