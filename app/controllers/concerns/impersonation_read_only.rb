# frozen_string_literal: true

module ImpersonationReadOnly
  extend ActiveSupport::Concern

  included do
    before_action :enforce_read_only_during_impersonation,
                  except: [:show, :index, :impersonate, :stop_impersonation, :enable_full_permissions, :disable_full_permissions]
  end

  private

  def enforce_read_only_during_impersonation
    return unless impersonating?
    return if session[:impersonation_full_permissions] == true

    if request.post? || request.patch? || request.put? || request.delete?
      if request.format.json?
        render json: {
          error: "Read-only mode: Cannot perform #{request.method} actions while impersonating"
        }, status: :forbidden
      else
        flash[:alert] = "Read-only mode: Cannot perform actions while impersonating a user."
        redirect_back(fallback_location: dashboard_path)
      end
    end
  end
end
