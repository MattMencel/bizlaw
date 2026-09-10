# frozen_string_literal: true

require "capybara/rspec"
require "selenium-webdriver"
require "axe-rspec"

# Inertia renders in the browser, so there is no server-rendered DOM for axe to
# read: a real driver is not a preference here. Vite builds the bundle on demand
# in test (`autoBuild` in `config/vite.json`), which is what makes these specs
# slower than the rest of the suite.
#
# They run by default — a suite that silently skips its only screen would report
# green on a page nobody rendered. `SKIP_SYSTEM_SPECS=1 bundle exec rspec` opts
# out when the view is untouched and the asset build is not worth waiting for.
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  end

  config.filter_run_excluding(type: :system) if ENV["SKIP_SYSTEM_SPECS"].present?
end
