require "rails_helper"

RSpec.describe "Navigation Active State", type: :system do
  let(:user) { create(:user, :admin) }
  let(:case_record) { create(:case) }

  before do
    sign_in user
  end

  describe "Cases navigation highlighting" do
    it "highlights only Case Status when on cases index page" do
      visit cases_path

      # Case Status should be highlighted (active)
      expect(page).to have_css('.navigation-section a[href="/cases"].bg-blue-600.text-white', text: "Case Status")

      # Other items should NOT be highlighted
      expect(page).not_to have_css('.navigation-section a[href="/cases/background"].bg-blue-600.text-white')
      expect(page).not_to have_css('.navigation-section a[href*="evidence_vault"].bg-blue-600.text-white')
      expect(page).not_to have_css('.navigation-section a[href="/annotations"].bg-blue-600.text-white')
      expect(page).not_to have_css('.navigation-section a[href="/document_search"].bg-blue-600.text-white')
      expect(page).not_to have_css('.navigation-section a[href="/cases/timeline"].bg-blue-600.text-white')
    end

    it "highlights only Case Background when on case background page" do
      visit background_cases_path

      # Case Background should be highlighted (active)
      expect(page).to have_css('.navigation-section a[href="/cases/background"].bg-blue-600.text-white', text: "Case Background")

      # Case Status should NOT be highlighted
      expect(page).not_to have_css('.navigation-section a[href="/cases"].bg-blue-600.text-white')
    end

    it "highlights only Timeline & Events when on timeline page" do
      visit timeline_cases_path

      # Timeline & Events should be highlighted (active)
      expect(page).to have_css('.navigation-section a[href="/cases/timeline"].bg-blue-600.text-white', text: "Timeline & Events")

      # Other items should NOT be highlighted
      expect(page).not_to have_css('.navigation-section a[href="/cases"].bg-blue-600.text-white')
      expect(page).not_to have_css('.navigation-section a[href="/cases/background"].bg-blue-600.text-white')
    end
  end

  describe "Evidence Management navigation highlighting" do
    it "highlights only Annotations when on annotations page" do
      visit annotations_path

      # Annotations should be highlighted (active)
      expect(page).to have_css('.navigation-section a[href="/annotations"].bg-blue-600.text-white', text: "Annotations")

      # Other evidence management items should NOT be highlighted
      expect(page).not_to have_css('.navigation-section a[href="/cases"].bg-blue-600.text-white')
      expect(page).not_to have_css('.navigation-section a[href*="evidence_vault"].bg-blue-600.text-white')
      expect(page).not_to have_css('.navigation-section a[href="/document_search"].bg-blue-600.text-white')
    end

    it "highlights only Document Search when on document search page" do
      visit document_search_index_path

      # Document Search should be highlighted (active)
      expect(page).to have_css('.navigation-section a[href="/document_search"].bg-blue-600.text-white', text: "Document Search")

      # Other items should NOT be highlighted
      expect(page).not_to have_css('.navigation-section a[href="/cases"].bg-blue-600.text-white')
      expect(page).not_to have_css('.navigation-section a[href="/annotations"].bg-blue-600.text-white')
    end
  end

  describe "Client Relations navigation highlighting" do
    it "highlights only Mood Tracking when on mood tracking page" do
      visit mood_tracking_index_path

      # Mood Tracking should be highlighted (active)
      expect(page).to have_css('.navigation-section a[href="/mood_tracking"].bg-blue-600.text-white', text: "Mood Tracking")

      # Other items should NOT be highlighted
      expect(page).not_to have_css('.navigation-section a[href="/cases"].bg-blue-600.text-white')
      expect(page).not_to have_css('.navigation-section a[href="/feedback_history"].bg-blue-600.text-white')
    end

    it "highlights only Feedback History when on feedback history page" do
      visit feedback_history_index_path

      # Feedback History should be highlighted (active)
      expect(page).to have_css('.navigation-section a[href="/feedback_history"].bg-blue-600.text-white', text: "Feedback History")

      # Other items should NOT be highlighted
      expect(page).not_to have_css('.navigation-section a[href="/cases"].bg-blue-600.text-white')
      expect(page).not_to have_css('.navigation-section a[href="/mood_tracking"].bg-blue-600.text-white')
    end
  end

  describe "Admin navigation highlighting" do
    it "highlights only Admin Dashboard when on admin dashboard" do
      visit admin_dashboard_path

      # Admin Dashboard should be highlighted (active)
      expect(page).to have_css('.navigation-section a[href="/admin/dashboard"].bg-blue-600.text-white', text: "Admin Dashboard")

      # Other admin items should NOT be highlighted
      expect(page).not_to have_css('.navigation-section a[href="/admin/organizations"].bg-blue-600.text-white')
      expect(page).not_to have_css('.navigation-section a[href="/admin/users"].bg-blue-600.text-white')
    end

    it "highlights admin section items when in same admin section" do
      visit admin_organizations_path

      # Organization should be highlighted (active)
      expect(page).to have_css('.navigation-section a[href="/admin/organizations"].bg-blue-600.text-white', text: "Organization")

      # Other admin sections should NOT be highlighted
      expect(page).not_to have_css('.navigation-section a[href="/admin/dashboard"].bg-blue-600.text-white')
      expect(page).not_to have_css('.navigation-section a[href="/admin/users"].bg-blue-600.text-white')
    end
  end

  describe "Navigation state persistence" do
    it "maintains correct highlighting when navigating between pages" do
      # Start on cases page
      visit cases_path
      expect(page).to have_css('.navigation-section a[href="/cases"].bg-blue-600.text-white', text: "Case Status")

      # Navigate to annotations
      click_link "Annotations"
      expect(page).to have_css('.navigation-section a[href="/annotations"].bg-blue-600.text-white', text: "Annotations")
      expect(page).not_to have_css('.navigation-section a[href="/cases"].bg-blue-600.text-white')

      # Navigate to mood tracking
      click_link "Mood Tracking"
      expect(page).to have_css('.navigation-section a[href="/mood_tracking"].bg-blue-600.text-white', text: "Mood Tracking")
      expect(page).not_to have_css('.navigation-section a[href="/annotations"].bg-blue-600.text-white')
    end
  end

  describe "Query parameter handling" do
    it "correctly handles active state with query parameters" do
      visit "#{cases_path}?page=2&status=active"

      # Should still highlight Case Status despite query parameters
      expect(page).to have_css('.navigation-section a[href="/cases"].bg-blue-600.text-white', text: "Case Status")
    end
  end
end
