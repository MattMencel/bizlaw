# frozen_string_literal: true

require "rails_helper"

# Google redirects back to this callback with a GET, and the controller responds the
# way the rest of the web app does: it signs the user in and redirects. The JWT that
# devise-jwt dispatches on this path only rides along on a POST callback, which the
# last example pins down.
RSpec.describe "Users::OmniauthCallbacks", type: :request do
  let(:callback_url) { "/users/auth/google_oauth2/callback" }
  let(:auth_hash) do
    OmniAuth::AuthHash.new({
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
    OmniAuth.config.mock_auth[:google_oauth2] = auth_hash
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
    it "creates a user from the auth hash and signs them in" do
      expect {
        get callback_url
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(dashboard_url)
      expect(session["warden.user.user.key"]).to be_present

      user = User.last
      expect(user.email).to eq("user@example.com")
      expect(user.first_name).to eq("John")
      expect(user.last_name).to eq("Doe")
      expect(user.provider).to eq("google_oauth2")
      expect(user.uid).to eq("123456789")
      expect(user.roles).to eq(["student"])
    end

    it "signs in an existing user without creating a duplicate" do
      create(:user, email: "user@example.com", provider: "google_oauth2", uid: "123456789")

      expect {
        get callback_url
      }.not_to change(User, :count)

      expect(response).to redirect_to(dashboard_url)
      expect(session["warden.user.user.key"]).to be_present
    end

    # Characterization: User.from_omniauth uses first_or_create, so profile fields on
    # an already-linked account are not refreshed from Google. Change this assertion
    # deliberately if that behaviour changes.
    it "does not refresh profile fields on an existing user" do
      existing_user = create(:user,
        email: "user@example.com",
        provider: "google_oauth2",
        uid: "123456789",
        first_name: "Old Name")

      get callback_url

      expect(existing_user.reload.first_name).to eq("Old Name")
    end
  end

  describe "POST /users/auth/google_oauth2/callback" do
    it "dispatches a JWT alongside the redirect" do
      post callback_url

      expect(response).to redirect_to(dashboard_url)
      expect(response.headers["Authorization"]).to start_with("Bearer ")
    end
  end
end
