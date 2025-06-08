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

  private

  def user_not_authorized
    if request.format.json?
      render json: { error: "You are not authorized to perform this action" }, status: :forbidden
    else
      flash[:alert] = "You are not authorized to perform this action."
      redirect_to(request.referrer || root_path)
    end
  end
end
