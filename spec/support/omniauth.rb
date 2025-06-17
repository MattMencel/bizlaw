# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    # Set test credentials for Google OAuth2 to prevent configuration warnings
    ENV["GOOGLE_CLIENT_ID"] = "test_client_id"
    ENV["GOOGLE_CLIENT_SECRET"] = "test_client_secret"
  end

  config.after(:suite) do
    # Clean up test credentials
    ENV.delete("GOOGLE_CLIENT_ID")
    ENV.delete("GOOGLE_CLIENT_SECRET")
  end

  config.before(:each, type: :request) do
    # Enable test mode for OmniAuth
    OmniAuth.config.test_mode = true
  end

  config.after(:each, type: :request) do
    # Clean up OmniAuth mock auth
    OmniAuth.config.mock_auth.clear
  end
end

# Configure OmniAuth for testing
OmniAuth.configure do |config|
  config.test_mode = true
  config.logger = Logger.new('/dev/null') # Suppress OmniAuth log messages
  config.on_failure = proc { |env| [401, {}, ['Authentication failed']] }
end