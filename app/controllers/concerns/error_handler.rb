module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError do |e|
      respond_to_error(e, :internal_server_error)
    end

    rescue_from ActiveRecord::RecordNotFound do |e|
      respond_to_error(e, :not_found)
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      respond_to_error(e, :unprocessable_entity)
    end

    rescue_from ActionController::ParameterMissing do |e|
      respond_to_error(e, :bad_request)
    end
  end

  private

  def respond_to_error(error, status)
    error_response = {
      status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status],
      error: status.to_s.titleize,
      message: error.message,
      timestamp: Time.current
    }

    # Add more details in development environment
    if Rails.env.development?
      error_response[:backtrace] = error.backtrace&.first(5)
    end

    render json: error_response, status: status
  end
end
