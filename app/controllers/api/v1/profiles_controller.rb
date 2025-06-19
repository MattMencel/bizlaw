# frozen_string_literal: true

module Api
  module V1
    class ProfilesController < BaseController
      def show
        render json: {
          status: {code: 200, message: "Profile retrieved successfully."},
          data: UserSerializer.new(current_user).serializable_hash[:data][:attributes]
        }
      end

      def update
        if current_user.update(profile_params)
          render json: {
            status: {code: 200, message: "Profile updated successfully."},
            data: UserSerializer.new(current_user).serializable_hash[:data][:attributes]
          }
        else
          render json: {
            status: {
              code: 422,
              message: "Profile couldn't be updated.",
              errors: current_user.errors.full_messages
            }
          }, status: :unprocessable_entity
        end
      end

      private

      def profile_params
        params.require(:user).permit(
          :first_name,
          :last_name,
          :email,
          :avatar_url,
          :password,
          :password_confirmation
        )
      end
    end
  end
end
