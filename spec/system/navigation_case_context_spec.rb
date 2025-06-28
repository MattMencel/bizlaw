# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Navigation Case Context", type: :system do
  let(:organization) { create(:organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:student) { create(:user, :student, organization: organization) }
  let(:course) { create(:course, instructor: instructor, organization: organization) }
  let(:case_obj) { create(:case, course: course) }
  let(:team) { create(:team) }
  let(:simulation) { create(:simulation, case: case_obj) }

  before do
    # Create case-team-simulation relationship
    create(:case_team, case: case_obj, team: team, simulation: simulation)
    student.teams << team
  end

  describe "Student with active case" do
    before do
      sign_in student
      visit dashboard_path
    end

    it "shows case-specific URLs in navigation" do
      # Check Document Vault link
      document_vault_link = find('a[href*="evidence_vault"]')
      expect(document_vault_link[:href]).to include(case_obj.id)
      expect(document_vault_link[:href]).not_to include("current")

      # Check Evidence Bundles link (should be same as Document Vault)
      evidence_bundles_link = all('a[href*="evidence_vault"]').last
      expect(evidence_bundles_link[:href]).to include(case_obj.id)
      expect(evidence_bundles_link[:href]).not_to include("current")

      # Check negotiation links
      negotiations_links = all('a[href*="negotiations"]')
      negotiations_links.each do |link|
        expect(link[:href]).to include(case_obj.id)
        expect(link[:href]).not_to include("current")
      end
    end

    it "displays current case information in case selector" do
      case_selector = find("button", text: case_obj.title)
      expect(case_selector).to have_text(case_obj.title)
      expect(case_selector).to have_text(team.role.humanize)
      expect(case_selector).to have_text("Student")
    end

    it "allows clicking on Document Vault link" do
      # Enable full permissions for this test since read-only mode might block navigation
      if page.has_button?("Enable Full Permissions")
        click_button "Enable Full Permissions"
      end

      document_vault_link = find("a", text: "Document Vault")

      # Verify the href is correct before clicking
      expect(document_vault_link[:href]).to match(%r{/cases/#{case_obj.id}/evidence_vault})

      # The actual navigation might fail due to evidence vault controller issues,
      # but the URL should be correct
      document_vault_link.click

      # Check that we navigated to the correct URL structure
      expect(page).to have_current_path("/cases/#{case_obj.id}/evidence_vault", ignore_query: true)
    end

    it "shows case dropdown with current case selected" do
      case_dropdown = find('button[data-navigation-menu-target="caseSwitcher"]', wait: 5)
      case_dropdown.click

      within('[data-navigation-menu-target="caseDropdown"]') do
        expect(page).to have_text("Current Selection")
        expect(page).to have_text(case_obj.title)
      end
    end
  end

  describe "Instructor without active case" do
    before do
      sign_in instructor
      visit dashboard_path
    end

    it "shows safe fallback URLs for case-dependent navigation" do
      # Check Document Vault link shows # fallback
      document_vault_link = find("a", text: "Document Vault")
      expect(document_vault_link[:href]).to eq("#")

      # Check Evidence Bundles link shows # fallback
      evidence_bundles_link = find("a", text: "Evidence Bundles")
      expect(evidence_bundles_link[:href]).to eq("#")

      # Check negotiation links show # fallbacks
      submit_offers_link = find("a", text: "Submit Offers")
      expect(submit_offers_link[:href]).to eq("#")

      templates_link = find("a", text: "Offer Templates")
      expect(templates_link[:href]).to eq("#")

      calculator_link = find("a", text: "Damage Calculator")
      expect(calculator_link[:href]).to eq("#")

      history_link = find("a", text: "Negotiation History")
      expect(history_link[:href]).to eq("#")
    end

    it "displays no active case in case selector" do
      case_selector = find("button", text: "Select a Case")
      expect(case_selector).to have_text("No Team")
      expect(case_selector).to have_text("Instructor")
    end

    it "shows 'No Active Case' when opening case dropdown" do
      case_dropdown = find("button", text: "Select a Case")
      case_dropdown.click

      expect(page).to have_text("Current Selection")
      expect(page).to have_text("No Active Case")
      expect(page).to have_text("No Team Assignment")
    end

    it "does not break when clicking safe fallback links" do
      document_vault_link = find("a", text: "Document Vault")

      # Clicking a # link should not navigate anywhere
      document_vault_link.click

      # Should stay on dashboard
      expect(page).to have_current_path(dashboard_path, ignore_query: true)
    end
  end

  describe "User with multiple cases" do
    let(:second_case) { create(:case, course: course) }
    let(:second_team) { create(:team) }
    let(:second_simulation) { create(:simulation, case: second_case) }

    before do
      # Add student to second case as well
      create(:case_team, case: second_case, team: second_team, simulation: second_simulation)
      student.teams << second_team

      sign_in student

      # Set active case in session to first case
      page.driver.browser.manage.add_cookie(
        name: "_bizlaw_session",
        value: {active_case_id: case_obj.id}.to_json
      )

      visit dashboard_path
    end

    it "shows navigation for the active case from session" do
      document_vault_link = find("a", text: "Document Vault")
      expect(document_vault_link[:href]).to include(case_obj.id)
      expect(document_vault_link[:href]).not_to include(second_case.id)
    end

    it "updates navigation when switching cases" do
      # This would test the context switching functionality
      # For now, we verify the current behavior
      expect(find("button", text: case_obj.title)).to be_present
    end
  end

  describe "Case selector dropdown functionality" do
    before do
      sign_in student
      visit dashboard_path
    end

    it "opens and closes properly" do
      case_selector = find("button", text: case_obj.title)

      # Dropdown should be closed initially
      expect(page).not_to have_text("Switch Case")

      # Click to open
      case_selector.click
      expect(page).to have_text("Current Selection")
      expect(page).to have_text("Switch Case")

      # Click outside or press escape to close (implementation dependent)
      case_selector.click
      expect(page).not_to have_text("Switch Case")
    end

    it "shows correct current selection details" do
      case_selector = find("button", text: case_obj.title)
      case_selector.click

      within('[data-navigation-menu-target="caseDropdown"]') do
        expect(page).to have_text(case_obj.title)
        expect(page).to have_text(team.role.humanize)
      end
    end
  end

  describe "Accessibility of navigation with case context" do
    before do
      sign_in student
      visit dashboard_path
    end

    it "maintains proper ARIA attributes" do
      case_selector = find("button", text: case_obj.title)
      expect(case_selector).to have_attribute("aria-expanded", "false")

      case_selector.click
      expect(case_selector).to have_attribute("aria-expanded", "true")
    end

    it "provides meaningful link text for screen readers" do
      document_vault_link = find("a", text: "Document Vault")
      expect(document_vault_link).to have_text("Document Vault")

      # Link should be descriptive even without case context
      evidence_bundles_link = find("a", text: "Evidence Bundles")
      expect(evidence_bundles_link).to have_text("Evidence Bundles")
    end
  end

  private

  def sign_in(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: user.password
    click_button "Sign in"
  end
end
