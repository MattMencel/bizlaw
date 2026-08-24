require "capybara/playwright/driver"

RSpec.configure do |config|
  # Headless by default so a local `rspec` run never steals focus with browser
  # windows. Set HEADED=1 to watch a spec drive a real browser.
  config.before(:each, type: :system) do
    driven_by :playwright, options: {
      browser: :chromium,
      headless: ENV["HEADED"].nil?,
      playwright_cli_executable_path: ENV["PLAYWRIGHT_CLI_EXECUTABLE_PATH"],
      playwright_server_executable_path: ENV["PLAYWRIGHT_SERVER_EXECUTABLE_PATH"]
    }
  end
end

Capybara.default_max_wait_time = 5
Capybara.server = :puma, {Silent: true}
