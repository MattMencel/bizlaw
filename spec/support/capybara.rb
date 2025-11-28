require "capybara/playwright/driver"

# Register the Playwright driver with Capybara
Capybara.register_driver(:playwright) do |app|
  options = {
    browser_type: :chromium,
    headless: ENV.fetch("HEADLESS", "true") != "false"
  }

  # Only add playwright paths if they are set
  options[:playwright_cli_executable_path] = ENV["PLAYWRIGHT_CLI_EXECUTABLE_PATH"] if ENV["PLAYWRIGHT_CLI_EXECUTABLE_PATH"]
  options[:playwright_server_executable_path] = ENV["PLAYWRIGHT_SERVER_EXECUTABLE_PATH"] if ENV["PLAYWRIGHT_SERVER_EXECUTABLE_PATH"]

  Capybara::Playwright::Driver.new(app, **options)
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :playwright
  end
end

Capybara.default_max_wait_time = 5
Capybara.server = :puma, {Silent: true}
