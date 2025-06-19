# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::OmniauthCallbacks", type: :request do
  let(:auth_hash) do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: "123456789",
      info: {
        email: "user@example.com",
        first_name: "John",
        last_name: "Doe",
        image: "https://example.com/photo.jpg"
      },
      credentials: {
        token: "mock_token",
        expires_at: 1.week.from_now.to_i,
        expires: true
      }
    })
  end

  before do
    OmniAuth.config.test_mode = true
    Rails.application.env_config["devise.mapping"] = Devise.mappings[:user]
    Rails.application.env_config["omniauth.auth"] = auth_hash
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    Rails.application.env_config["devise.mapping"] = nil
    Rails.application.env_config["omniauth.auth"] = nil
  end

  describe "GET /users/auth/google_oauth2/callback" do
    context "when OAuth authentication is successful" do
      it "creates a new user if one doesn't exist" do
        expect {
          get "/users/auth/google_oauth2/callback"
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(response.headers["Authorization"]).to be_present

        user = User.last
        expect(user.email).to eq("user@example.com")
        expect(user.first_name).to eq("John")
        expect(user.last_name).to eq("Doe")
        expect(user.avatar_url).to eq("https://example.com/photo.jpg")
      end

      it "signs in an existing user" do
        create(:user, email: "user@example.com", provider: "google_oauth2", uid: "123456789")

        expect {
          get "/users/auth/google_oauth2/callback"
        }.not_to change(User, :count)

        expect(response).to have_http_status(:ok)
        expect(response.headers["Authorization"]).to be_present
      end

      it "updates existing user information" do
        existing_user = create(:user,
          email: "user@example.com",
          provider: "google_oauth2",
          uid: "123456789",
          first_name: "Old Name",
          avatar_url: "old_photo.jpg")

        get "/users/auth/google_oauth2/callback"

        existing_user.reload
        expect(existing_user.first_name).to eq("John")
        expect(existing_user.avatar_url).to eq("https://example.com/photo.jpg")
      end
    end

    context "when OAuth authentication fails" do
      before do
        OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
      end

      it "redirects to login with error" do
        get "/users/auth/google_oauth2/callback"

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Google authentication failed")
      end
    end
  end

  describe "GET /users/auth/google_oauth2/failure" do
    it "returns error message" do
      get "/users/auth/failure"

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)["error"]).to eq("Google authentication failed")
    end
  end
end
