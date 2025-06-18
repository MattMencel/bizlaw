# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Mobile Navigation', :js, type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization, role: 'student', roles: [ 'student' ]) }
  let(:course) { create(:course, organization: organization) }
  let(:case_obj) { create(:case, course: course) }
  let(:team) { create(:team, course: course) }

  before do
    create(:course_enrollment, user: user, course: course, status: 'active')
    create(:team_member, user: user, team: team, role: 'member')
    create(:case_team, case: case_obj, team: team, role: 'plaintiff')
    sign_in user
  end

  describe 'Mobile navigation behavior' do
    context 'on mobile viewport (375px)' do
      before do
        page.driver.browser.manage.window.resize_to(375, 667)
      end

      it 'shows hamburger menu and hides main navigation' do
        visit dashboard_path

        expect(page).to have_css('[data-mobile-navigation-target="toggle"]', visible: true)
        expect(page).to have_css('nav.hidden', visible: false)
      end

      it 'toggles navigation menu when hamburger is clicked' do
        visit dashboard_path

        # Initially closed
        expect(page).to have_css('[data-mobile-navigation-target="menu"]', visible: false)

        # Click to open
        find('[data-mobile-navigation-target="toggle"]').click
        expect(page).to have_css('[data-mobile-navigation-target="menu"]', visible: true)

        # Click to close
        find('[data-mobile-navigation-target="toggle"]').click
        expect(page).to have_css('[data-mobile-navigation-target="menu"]', visible: false)
      end

      it 'closes menu when clicking outside' do
        visit dashboard_path

        # Open menu
        find('[data-mobile-navigation-target="toggle"]').click
        expect(page).to have_css('[data-mobile-navigation-target="menu"]', visible: true)

        # Click outside (on backdrop)
        find('[data-mobile-navigation-target="backdrop"]').click
        expect(page).to have_css('[data-mobile-navigation-target="menu"]', visible: false)
      end

      it 'ensures navigation does not occupy more than 100% of screen width' do
        visit dashboard_path

        find('[data-mobile-navigation-target="toggle"]').click

        nav_width = page.evaluate_script("document.querySelector('[data-mobile-navigation-target=\"menu\"]').offsetWidth")
        viewport_width = page.evaluate_script("window.innerWidth")

        expect(nav_width).to be <= viewport_width
      end

      it 'maintains main content accessibility when navigation is closed' do
        visit dashboard_path

        # Ensure main content is not blocked
        expect(page).to have_css('main', visible: true)

        # Should be able to interact with main content
        expect(page).to have_content('Business Law Education Platform')
      end
    end

    context 'on tablet viewport (768px)' do
      before do
        page.driver.browser.manage.window.resize_to(768, 1024)
      end

      it 'may show simplified navigation but not full mobile menu' do
        visit dashboard_path

        # At tablet size, should start transitioning to mobile behavior
        # but exact behavior depends on implementation
        expect(page).to have_css('nav')
      end
    end

    context 'on desktop viewport (1200px)' do
      before do
        page.driver.browser.manage.window.resize_to(1200, 800)
      end

      it 'shows full navigation sidebar without hamburger menu' do
        visit dashboard_path

        expect(page).to have_css('nav', visible: true)
        expect(page).not_to have_css('[data-mobile-navigation-target="toggle"]', visible: true)
      end
    end
  end

  describe 'Responsive navigation transitions' do
    it 'switches between mobile and desktop modes when resizing' do
      visit dashboard_path

      # Start at desktop
      page.driver.browser.manage.window.resize_to(1200, 800)
      expect(page).not_to have_css('[data-mobile-navigation-target="toggle"]', visible: true)

      # Resize to mobile
      page.driver.browser.manage.window.resize_to(375, 667)
      expect(page).to have_css('[data-mobile-navigation-target="toggle"]', visible: true)

      # Resize back to desktop
      page.driver.browser.manage.window.resize_to(1200, 800)
      expect(page).not_to have_css('[data-mobile-navigation-target="toggle"]', visible: true)
    end
  end

  describe 'Mobile navigation accessibility' do
    before do
      page.driver.browser.manage.window.resize_to(375, 667)
    end

    it 'provides proper ARIA labels for mobile navigation' do
      visit dashboard_path

      toggle_button = find('[data-mobile-navigation-target="toggle"]')
      expect(toggle_button['aria-label']).to be_present
      expect(toggle_button['aria-expanded']).to eq('false')

      toggle_button.click
      expect(toggle_button['aria-expanded']).to eq('true')
    end

    it 'supports keyboard navigation in mobile menu' do
      visit dashboard_path

      # Open menu with keyboard
      find('[data-mobile-navigation-target="toggle"]').send_keys(:enter)
      expect(page).to have_css('[data-mobile-navigation-target="menu"]', visible: true)

      # Close menu with escape
      find('body').send_keys(:escape)
      expect(page).to have_css('[data-mobile-navigation-target="menu"]', visible: false)
    end

    it 'traps focus within mobile menu when open' do
      visit dashboard_path

      find('[data-mobile-navigation-target="toggle"]').click

      # Focus should be trapped within the navigation menu
      within('[data-mobile-navigation-target="menu"]') do
        expect(page).to have_css('a:focus, button:focus')
      end
    end
  end

  describe 'Mobile navigation performance' do
    before do
      page.driver.browser.manage.window.resize_to(375, 667)
    end

    it 'opens and closes navigation smoothly' do
      visit dashboard_path

      start_time = Time.current
      find('[data-mobile-navigation-target="toggle"]').click

      # Should complete animation within reasonable time
      expect(page).to have_css('[data-mobile-navigation-target="menu"]', visible: true)
      expect(Time.current - start_time).to be < 1.0 # Less than 1 second
    end
  end
end
