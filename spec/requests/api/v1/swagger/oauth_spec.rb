# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "OAuth Authentication API", type: :request do
  path "/users/auth/google_oauth2/callback" do
    get "Handle Google OAuth2 callback" do
      tags "Authentication"
      produces "application/json"
      security [ google_oauth2: [] ]

      response "200", "User authenticated successfully" do
        let(:auth_hash) do
          OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
            provider: "google_oauth2",
            uid: "123456789",
            info: {
              email: "user@example.com",
              first_name: "John",
              last_name: "Doe",
              image: "https://example.com/photo.jpg"
            }
          })
        end

        before do
          OmniAuth.config.test_mode = true
          Rails.application.env_config["devise.mapping"] = Devise.mappings[:user]
          Rails.application.env_config["omniauth.auth"] = auth_hash
OmniAuth.config.test_mode = true
          OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
        end

        after do
          OmniAuth.config.test_mode = false
          OmniAuth.config.mock_auth[:google_oauth2] = nil
          Rails.application.env_config["devise.mapping"] = nil
          Rails.application.env_config["omniauth.auth"] = nil
OmniAuth.config.test_mode = false
          OmniAuth.config.mock_auth[:google_oauth2] = nil
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(response.headers["Authorization"]).to be_present
          expect(data["user"]["email"]).to eq("user@example.com")
        end
      end

      response "401", "Authentication failed" do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Google authentication failed")
        end
      end
    end
  end

  path "/users/auth/failure" do
    get "Handle OAuth failure" do
      tags "Authentication"
      produces "application/json"

      response "401", "Authentication failed" do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Google authentication failed")
        end
      end
    end
  end
end
