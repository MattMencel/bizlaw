# frozen_string_literal: true

module AuthenticationHelpers
  def sign_in_user(user)
    login_as(user)
  end

  def sign_out_user
    logout(:user)
  end

  def mock_google_oauth(email: "user@example.com", first_name: "Test", last_name: "User")
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "123456789",
      info: {
        email: email,
        first_name: first_name,
        last_name: last_name,
        image: "https://example.com/photo.jpg"
      },
      credentials: {
        token: "mock_token",
        refresh_token: "mock_refresh_token",
        expires_at: Time.current.to_i + 3600,
        expires: true
      }
    )
  end

  def mock_google_oauth_failure
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
  end
end

World(AuthenticationHelpers)
