require "capybara/playwright/driver"

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :playwright, options: {
      browser: :chromium,
      headless: !ENV["HEADLESS"].nil?,
      playwright_cli_executable_path: ENV["PLAYWRIGHT_CLI_EXECUTABLE_PATH"],
      playwright_server_executable_path: ENV["PLAYWRIGHT_SERVER_EXECUTABLE_PATH"]
    }
  end
end

Capybara.default_max_wait_time = 5
Capybara.server = :puma, {Silent: true}
