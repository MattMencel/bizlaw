# frozen_string_literal: true

module Api
  module V1
    class SessionsController < Devise::SessionsController
      include RackSessionsFix
      respond_to :json

      private

      # Devise's version only inspects the session, so a JWT-bearing request looks
      # already signed out. Authenticating the token first makes all_signed_out?
      # false; hold onto the user because sign_out clears it before we respond.
      def verify_signed_out_user
        @signed_out_user = current_user
        super
      end

      def respond_with(resource, _opts = {})
        if resource.persisted?
          render json: {
            status: {code: 200, message: "Logged in successfully."},
            data: {
              user: UserSerializer.new(resource).serializable_hash[:data][:attributes],
              token: request.env["warden-jwt_auth.token"]
            }
          }
        else
          render json: {
            status: {code: 401, message: "Invalid email or password."}
          }, status: :unauthorized
        end
      end

      # Devise 5 passes non_navigational_status:; this renders JSON with its own
      # statuses, so the keyword is accepted and ignored.
      def respond_to_on_destroy(**)
        if @signed_out_user
          render json: {
            status: {code: 200, message: "Logged out successfully."}
          }
        else
          render json: {
            status: {code: 401, message: "Couldn't find an active session."}
          }, status: :unauthorized
        end
      end
    end
  end
end
