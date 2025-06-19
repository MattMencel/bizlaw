# frozen_string_literal: true

module Api
  class ApiController < ApplicationController
    include ActionController::MimeResponds

    # Skip CSRF token verification for API requests
    skip_before_action :verify_authenticity_token

    # Ensure JSON format for all API requests
    before_action :ensure_json_request
    before_action :set_default_format
    before_action :check_version_deprecation

    # Handle common errors with JSON responses
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
    rescue_from ActionController::ParameterMissing, with: :bad_request
    rescue_from Pundit::NotAuthorizedError, with: :forbidden

    private

    def ensure_json_request
      return if request.format.json?

      render json: {error: "Only JSON requests are accepted"},
        status: :not_acceptable
    end

    def not_found(exception)
      render json: {
        error: "Resource not found",
        detail: exception.message
      }, status: :not_found
    end

    def unprocessable_entity(exception)
      render json: {
        error: "Validation failed",
        details: exception.record.errors.full_messages
      }, status: :unprocessable_entity
    end

    def bad_request(exception)
      render json: {
        error: "Bad request",
        detail: exception.message
      }, status: :bad_request
    end

    def forbidden(exception)
      render json: {
        error: "Access denied",
        detail: exception.message
      }, status: :forbidden
    end

    # Helper method to paginate collections
    def paginate(collection)
      collection.page(params[:page] || 1).per(params[:per_page] || 25)
    end

    def set_default_format
      request.format = :json unless params[:format]
    end

    def check_version_deprecation
      return unless version_deprecated?

      response.headers["Warning"] = version_deprecation_message
      response.headers["Sunset"] = version_sunset_date if version_sunset_date
    end

    def version_deprecated?
      # Add version deprecation logic here
      # Example: Version 1 will be deprecated after 2024-12-31
      current_version == 1 && Date.current > Date.new(2024, 12, 31)
    end

    def version_sunset_date
      # Add sunset dates for deprecated versions
      "2025-12-31" if current_version == 1
    end

    def version_deprecation_message
      "299 api.business-law.com \"This version of the API has been deprecated and will be discontinued on #{version_sunset_date}. Please migrate to the latest version.\""
    end

    def current_version
      # Extract version from request path
      request.path.match(/\/api\/v(\d+)/)&.[](1)&.to_i || 1
    end

    def api_version
      accept_header = request.headers["Accept"]
      if accept_header&.include?("application/vnd.business-law")
        accept_header.match(/application\/vnd\.business-law\.v(\d+)\+json/)&.[](1)&.to_i
      end
    end
  end
end
