# frozen_string_literal: true

Rails.application.configure do
  # Skip license enforcement in development and test environments
  # This allows developers to test the app without license restrictions
  # Set to false in production or when testing license functionality
  config.skip_license_enforcement = Rails.env.development? || Rails.env.test?

  # You can override this with an environment variable
  if ENV['ENFORCE_LICENSES'].present?
    config.skip_license_enforcement = ENV['ENFORCE_LICENSES'].downcase == 'false'
  end
end
