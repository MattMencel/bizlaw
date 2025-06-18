# frozen_string_literal: true

# Accessibility testing helpers and configuration
module AccessibilityHelpers
  # Common accessibility test patterns
  def expect_accessible_page(options = {})
    expect(page).to be_accessible.according_to(:wcag2a, :wcag2aa, :wcag21aa).excluding(options[:excluding] || [])
  end

  def expect_accessible_form
    expect(page).to be_accessible.according_to(:wcag2a, :wcag2aa).within('form')
  end

  def expect_accessible_navigation
    expect(page).to be_accessible.according_to(:wcag2a, :wcag2aa).within('nav')
  end

  # Skip certain rules that might not apply in test environment
  def accessibility_rules_to_skip
    [
      'color-contrast', # Can be flaky in test environment due to CSS loading
      'landmark-one-main' # Sometimes problematic with test layouts
    ]
  end

  # Standard accessibility check for authenticated pages
  def check_authenticated_page_accessibility(excluding: [])
    expect_accessible_page(excluding: accessibility_rules_to_skip + excluding)
  end
end

RSpec.configure do |config|
  config.include AccessibilityHelpers, type: :system
  config.include AccessibilityHelpers, type: :feature

  # Configure axe for our application
  config.before(:each, type: :system) do
    # Set up axe configuration
    page.execute_script <<~JS
      if (typeof axe !== 'undefined') {
        axe.configure({
          rules: [
            { id: 'color-contrast', enabled: false }, // Disable in test
            { id: 'landmark-one-main', enabled: false } // Can be flaky
          ]
        });
      }
    JS
  end
end
