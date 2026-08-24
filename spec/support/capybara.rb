require "capybara/playwright/driver"

# Headless by default so a plain `rspec` run never steals focus with browser
# windows. Set HEADED=1 to watch a spec drive a real browser.
#
# Cast rather than test for presence: HEADED=0 and HEADED=false should mean
# headless, which is the trap the old HEADLESS flag fell into.
#
# These options have to be passed at every `driven_by :playwright` call site.
# Rails' driven_by re-registers the driver each time it runs, so a
# Capybara.register_driver default here would be silently discarded, and a bare
# `driven_by :playwright` falls back to the driver's own headed default.
module PlaywrightDriverOptions
  def self.call
    {
      browser_type: :chromium,
      headless: !ActiveModel::Type::Boolean.new.cast(ENV["HEADED"]),
      playwright_cli_executable_path: ENV["PLAYWRIGHT_CLI_EXECUTABLE_PATH"],
      playwright_server_executable_path: ENV["PLAYWRIGHT_SERVER_EXECUTABLE_PATH"]
    }.compact
  end
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :playwright, options: PlaywrightDriverOptions.call
  end
end

Capybara.default_max_wait_time = 5
Capybara.server = :puma, {Silent: true}
