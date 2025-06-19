# frozen_string_literal: true

module Api
  module V1
    class OmniauthCallbacksController < Devise::OmniauthCallbacksController
      include RackSessionsFix

      def google_oauth2
        handle_auth "Google"
      end

      def failure
        render json: {
          status: {
            code: 401,
            message: "Authentication failed",
            errors: [request.env["omniauth.error"].to_s]
          }
        }, status: :unauthorized
      end

      private

      def handle_auth(kind)
        @user = User.from_omniauth(request.env["omniauth.auth"])
        if @user.persisted?
          sign_in @user
          render json: {
            status: {code: 200, message: "Signed in successfully with #{kind}."},
            data: {
              user: UserSerializer.new(@user).serializable_hash[:data][:attributes],
              token: request.env["warden-jwt_auth.token"]
            }
          }
        else
          render json: {
            status: {
              code: 422,
              message: "Authentication failed",
              errors: @user.errors.full_messages
            }
          }, status: :unprocessable_entity
        end
      end
    end
  end
end
