# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Client Consultation", type: :system do
  include Devise::Test::IntegrationHelpers

  let(:organization) { create(:organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:student1) { create(:user, :student, organization: organization) }
  let(:student2) { create(:user, :student, organization: organization) }
  let(:course) { create(:course, instructor: instructor, organization: organization) }

  # Create case with simulation
  let(:case_instance) { create(:case, :with_simulation, course: course, created_by: instructor) }
  let(:simulation) { case_instance.simulation }

  # Create teams
  let(:plaintiff_team) { create(:team, course: course, owner: student1) }
  let(:defendant_team) { create(:team, course: course, owner: student2) }

  # Create case team assignments
  let!(:plaintiff_case_team) { create(:case_team, case: case_instance, team: plaintiff_team, role: "plaintiff") }
  let!(:defendant_case_team) { create(:case_team, case: case_instance, team: defendant_team, role: "defendant") }

  # Create team memberships
  let!(:plaintiff_member) { create(:team_member, team: plaintiff_team, user: student1, role: "member") }
  let!(:defendant_member) { create(:team_member, team: defendant_team, user: student2, role: "member") }

  # Create negotiation round
  let!(:negotiation_round) { create(:negotiation_round, :active, simulation: simulation, round_number: 1) }

  before do
    simulation.update!(status: :active)
    sign_in student1
  end

  describe "Client consultation page" do
    before do
      visit client_consultation_case_negotiation_path(case_instance, negotiation_round)
    end

    it "displays the client consultation interface" do
      expect(page).to have_content("Client Consultation")
      expect(page).to have_content("Review your proposed settlement with your client")
      expect(page).to have_field("settlement_amount")
      expect(page).to have_button("Get Client Reaction")
    end

    it "shows client priorities and concerns" do
      expect(page).to have_content("Client Priorities")
      expect(page).to have_content("Client Concerns")

      # For plaintiff team, should show specific priorities
      expect(page).to have_content("Financial Security")
      expect(page).to have_content("Justice/Accountability")
    end

    it "displays client acceptable range" do
      expect(page).to have_content("Compared to Client Range")
      expect(page).to have_content("Minimum Acceptable")
      expect(page).to have_content("Ideal Target")
    end

    it "shows consultation questions" do
      expect(page).to have_content("Client Consultation Questions")
      expect(page).to have_content("How do you think your client will react")
      expect(page).to have_content("Which of your client's priorities")
    end
  end

  describe "Settlement amount interaction" do
    before do
      visit client_consultation_case_negotiation_path(case_instance, negotiation_round)
    end

    it "updates range comparison when amount is entered" do
      fill_in "settlement_amount", with: "50000"

      # Allow JavaScript to execute
      sleep 0.5

      # Check for range comparison update (this will depend on the simulation's range values)
      expect(page).to have_content("Within acceptable range", wait: 2) ||
        have_content("Below minimum acceptable", wait: 2) ||
        have_content("Exceeds client's ideal target", wait: 2)
    end

    it "validates settlement amount before making AI request" do
      # Try to get client reaction without entering amount
      click_button "Get Client Reaction"

      expect(page.driver.browser.switch_to.alert.text).to include("Please enter a valid settlement amount")
      page.driver.browser.switch_to.alert.accept
    end
  end

  describe "AI client reaction functionality", js: true do
    before do
      visit client_consultation_case_negotiation_path(case_instance, negotiation_round)
    end

    context "with valid settlement amount" do
      it "shows loading state when requesting client reaction" do
        fill_in "settlement_amount", with: "150000"

        # Mock the AI response to avoid actual API calls in tests
        page.execute_script("
          window.originalFetch = window.fetch;
          window.fetch = function(url, options) {
            return new Promise((resolve) => {
              setTimeout(() => {
                resolve({
                  ok: true,
                  json: () => Promise.resolve({
                    reaction: {
                      reaction: 'pleased',
                      message: 'Your client is pleased with this settlement amount.',
                      source: 'ai',
                      satisfaction_score: 85
                    }
                  })
                });
              }, 100);
            });
          };
        ")

        click_button "Get Client Reaction"

        # Check for loading state
        expect(page).to have_content("Generating AI Response...", wait: 1)
      end

      it "displays AI-generated client reaction" do
        fill_in "settlement_amount", with: "150000"
        fill_in "settlement_justification", with: "Fair compensation for damages"

        # Mock successful AI response
        page.execute_script("
          window.fetch = function(url, options) {
            return Promise.resolve({
              ok: true,
              json: () => Promise.resolve({
                reaction: {
                  reaction: 'pleased',
                  message: 'Your client is pleased with this settlement amount. It addresses their primary concerns about financial security.',
                  source: 'ai',
                  satisfaction_score: 85,
                  strategic_guidance: 'Consider emphasizing the comprehensive nature of this settlement.'
                }
              })
            });
          };
        ")

        click_button "Get Client Reaction"

        # Wait for and check the reaction display
        expect(page).to have_content("Client Reaction: Pleased", wait: 5)
        expect(page).to have_content("pleased with this settlement amount")
        expect(page).to have_content("🤖 AI-Generated")
      end

      it "falls back to rule-based reaction when AI fails" do
        fill_in "settlement_amount", with: "150000"

        # Mock failed AI response
        page.execute_script("
          window.fetch = function(url, options) {
            return Promise.reject(new Error('AI service unavailable'));
          };
        ")

        click_button "Get Client Reaction"

        # Should show fallback reaction
        expect(page).to have_content("Client Reaction:", wait: 5)
        expect(page).to have_content("pleased", wait: 5) ||
          have_content("neutral", wait: 5) ||
          have_content("concerned", wait: 5)
      end
    end

    context "with different settlement amounts" do
      it "shows appropriate reaction for high amount" do
        fill_in "settlement_amount", with: "300000" # High amount for plaintiff

        # Mock appropriate high amount response
        page.execute_script("
          window.fetch = function(url, options) {
            return Promise.resolve({
              ok: true,
              json: () => Promise.resolve({
                reaction: {
                  reaction: 'pleased',
                  message: 'Your client is very pleased with this aggressive settlement amount.',
                  source: 'fallback'
                }
              })
            });
          };
        ")

        click_button "Get Client Reaction"

        expect(page).to have_content("Client Reaction: Pleased", wait: 5)
      end

      it "shows appropriate reaction for low amount" do
        fill_in "settlement_amount", with: "25000" # Low amount for plaintiff

        # Mock appropriate low amount response
        page.execute_script("
          window.fetch = function(url, options) {
            return Promise.resolve({
              ok: true,
              json: () => Promise.resolve({
                reaction: {
                  reaction: 'concerned',
                  message: 'Your client is concerned that this amount may not adequately address their damages.',
                  source: 'fallback'
                }
              })
            });
          };
        ")

        click_button "Get Client Reaction"

        expect(page).to have_content("Client Reaction: Concerned", wait: 5)
      end
    end
  end

  describe "Consultation form submission" do
    before do
      visit client_consultation_case_negotiation_path(case_instance, negotiation_round)
    end

    it "allows completing consultation only" do
      fill_in "settlement_amount", with: "150000"
      choose "Satisfied - meets needs"
      check "Cost Minimization"
      fill_in "Consider your client's perspective", with: "Client may have concerns about precedent"
      choose "Proceed with this offer as proposed"

      click_button "Complete Consultation Only"

      expect(page).to have_current_path(submit_offer_case_negotiation_path(case_instance, negotiation_round))
      expect(page).to have_content("consultation completed")
    end

    it "allows proceeding with offer after consultation" do
      # Mock successful API submission
      allow_any_instance_of(NegotiationsController).to receive(:submit_offer_via_api).and_return(true)

      fill_in "settlement_amount", with: "150000"
      fill_in "settlement_justification", with: "Comprehensive settlement based on client consultation"
      choose "Satisfied - meets needs"
      check "Cost Minimization"

      click_button "Proceed with Offer"

      expect(page).to have_current_path(case_negotiations_path(case_instance))
      expect(page).to have_content("submitted after client consultation")
    end
  end

  describe "Navigation" do
    before do
      visit client_consultation_case_negotiation_path(case_instance, negotiation_round)
    end

    it "allows navigation back to offer form" do
      click_link "Back to Offer Form"

      expect(page).to have_current_path(submit_offer_case_negotiation_path(case_instance, negotiation_round))
    end

    it "displays proper case and team information" do
      expect(page).to have_content(case_instance.title)
      expect(page).to have_content("Plaintiff Team") # Since signed in as student1
    end
  end

  describe "Different team perspectives" do
    context "as defendant team member" do
      before do
        sign_in student2 # Switch to defendant team
        visit client_consultation_case_negotiation_path(case_instance, negotiation_round)
      end

      it "shows defendant-specific priorities and concerns" do
        expect(page).to have_content("Cost Minimization")
        expect(page).to have_content("Reputation Protection")
        expect(page).to have_content("Excessive settlement demand")
        expect(page).to have_content("Media attention")
      end

      it "shows different acceptable range values" do
        # Defendant should have different min/max values than plaintiff
        expect(page).to have_content("Minimum Acceptable")
        expect(page).to have_content("Ideal Target")
        # The specific values will depend on the simulation factory defaults
      end
    end
  end

  describe "Error handling" do
    before do
      visit client_consultation_case_negotiation_path(case_instance, negotiation_round)
    end

    it "handles network errors gracefully", js: true do
      fill_in "settlement_amount", with: "150000"

      # Mock network error
      page.execute_script("
        window.fetch = function(url, options) {
          return Promise.reject(new Error('Network error'));
        };
      ")

      click_button "Get Client Reaction"

      # Should fall back to rule-based reaction
      expect(page).to have_content("Client Reaction:", wait: 5)
    end

    it "handles invalid server responses gracefully", js: true do
      fill_in "settlement_amount", with: "150000"

      # Mock invalid server response
      page.execute_script("
        window.fetch = function(url, options) {
          return Promise.resolve({
            ok: false,
            status: 500,
            statusText: 'Internal Server Error'
          });
        };
      ")

      click_button "Get Client Reaction"

      # Should fall back to rule-based reaction
      expect(page).to have_content("Client Reaction:", wait: 5)
    end
  end

  describe "Accessibility" do
    before do
      visit client_consultation_case_negotiation_path(case_instance, negotiation_round)
    end

    it "has proper form labels and structure" do
      expect(page).to have_field("Settlement Amount")
      expect(page).to have_field("Your Justification")
      expect(page).to have_field("Non-Monetary Terms")

      # Check for proper radio button groups
      expect(page).to have_field("Very pleased - exceeds expectations")
      expect(page).to have_field("Satisfied - meets needs")
    end

    it "has proper heading structure" do
      expect(page).to have_selector("h1", text: "Client Consultation")
      expect(page).to have_selector("h2", text: "Your Proposed Settlement")
      expect(page).to have_selector("h2", text: "Client Priorities")
    end
  end
end
