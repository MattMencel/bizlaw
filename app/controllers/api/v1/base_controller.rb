# frozen_string_literal: true

module Api
  module V1
    # Base controller for API V1 endpoints with common functionality
    class BaseController < ApplicationController
      include PerformanceMonitoring

      before_action :reset_metrics
      after_action :track_error_details, if: -> { response.status >= 400 }

      # Add version-specific configuration here
      before_action :authenticate_user!

      private

      def reset_metrics
        ActiveRecord::QueryCounter.reset!
      end

      def track_error_details
        error_data = {
          message: response.body,
          backtrace: Rails.backtrace_cleaner.clean(caller),
          params: request.filtered_parameters
        }

        MetricsService.track_error_details(
          endpoint: "#{controller_name}##{action_name}",
          version: "1",
          status: response.status,
          error_data: error_data
        )
      end

      def current_user
        @current_user ||= warden.user
      end

      # Version-specific error handling can be added here
      def api_error(message:, status: :unprocessable_entity, details: nil)
        error_response = {
          error: message,
          status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status]
        }
        error_response[:details] = details if details.present?

        render json: error_response, status: status
      end
    end
  end
end
