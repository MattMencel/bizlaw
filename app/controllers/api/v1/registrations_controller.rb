# frozen_string_literal: true

module Api
  module V1
    class RegistrationsController < Devise::RegistrationsController
      include RackSessionsFix
      respond_to :json

      private

      def respond_with(resource, _opts = {})
        if resource.persisted?
          render json: {
            status: {code: 200, message: "Signed up successfully."},
            data: {
              user: UserSerializer.new(resource).serializable_hash[:data][:attributes],
              token: request.env["warden-jwt_auth.token"]
            }
          }
        else
          render json: {
            status: {
              code: 422,
              message: "User couldn't be created successfully.",
              errors: resource.errors.full_messages
            }
          }, status: :unprocessable_entity
        end
      end

      def sign_up_params
        params.require(:user).permit(
          :email,
          :password,
          :password_confirmation,
          :first_name,
          :last_name
        )
      end
    end
  end
end
