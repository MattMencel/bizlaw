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

# A field named by `aria-label` is findable by that name. The term sheet is a
# table, and the one field on it that takes a figure is named the way a cell in
# a table has to be — by ARIA, since the visible label in the row header belongs
# to the checkbox beside it and a second `<label for>` would name two controls
# one thing. Capybara ignores `aria-label` unless told not to, which would leave
# a spec reaching for that field by CSS while a screen reader reaches it by
# name — two answers to the question the label exists to settle.
Capybara.enable_aria_label = true

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  end

  config.filter_run_excluding(type: :system) if ENV["SKIP_SYSTEM_SPECS"].present?
end
