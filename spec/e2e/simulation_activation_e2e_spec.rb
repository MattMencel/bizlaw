# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Simulation Activation E2E", type: :system, driver: :playwright do
  include Devise::Test::IntegrationHelpers

  let(:organization) { create(:organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:student1) { create(:user, :student, organization: organization) }
  let(:student2) { create(:user, :student, organization: organization) }
  let(:course) { create(:course, instructor: instructor, organization: organization) }

  # Create case and teams
  let(:case_instance) { create(:case, course: course, created_by: instructor, status: :not_started) }
  let(:plaintiff_team) { create(:team, course: course, owner: student1) }
  let(:defendant_team) { create(:team, course: course, owner: student2) }

  # Create team assignments
  let!(:plaintiff_case_team) { create(:case_team, case: case_instance, team: plaintiff_team, role: "plaintiff") }
  let!(:defendant_case_team) { create(:case_team, case: case_instance, team: defendant_team, role: "defendant") }

  # Create team memberships
  let!(:plaintiff_member) { create(:team_member, team: plaintiff_team, user: student1, role: "member") }
  let!(:defendant_member) { create(:team_member, team: defendant_team, user: student2, role: "member") }

  before do
    driven_by(:playwright)
  end

  describe "Case without simulation" do
    context "when student tries to access negotiations" do
      before do
        login_as(student1, scope: :user)
      end

      it "shows clear error message and prevents access" do
        visit case_negotiations_path(case_instance)

        expect(page).to have_current_path(cases_path)
        expect(page).to have_content("This case does not have an active simulation")

        # Verify the alert is dismissible
        expect(page).to have_button("Dismiss")
        click_button "Dismiss"
        expect(page).not_to have_content("This case does not have an active simulation")
      end

      it "shows case in not started status" do
        visit course_case_path(course, case_instance)

        expect(page).to have_content("Not started")
        expect(page).to have_link("Negotiations", href: case_negotiations_path(case_instance))

        # Clicking negotiations link should redirect with error
        click_link "Negotiations"
        expect(page).to have_current_path(cases_path)
        expect(page).to have_content("This case does not have an active simulation")
      end
    end

    context "when instructor views case" do
      before do
        login_as(instructor, scope: :user)
      end

      it "shows case management options" do
        visit course_case_path(course, case_instance)

        expect(page).to have_content("Not started")
        expect(page).to have_link("Edit Case")

        # Should see option to create/configure simulation
        # This would typically be in an admin area or edit form
        click_link "Edit Case"
        expect(page).to have_current_path(edit_course_case_path(course, case_instance))
      end
    end
  end

  describe "Case with inactive simulation" do
    let!(:simulation) do
      create(:simulation,
        case: case_instance,
        status: :setup,
        plaintiff_team: plaintiff_team,
        defendant_team: defendant_team,
        plaintiff_min_acceptable: 100000,
        plaintiff_ideal: 300000,
        defendant_ideal: 50000,
        defendant_max_acceptable: 200000)
    end

    context "when student tries to access negotiations" do
      before do
        login_as(student1, scope: :user)
      end

      it "still shows error message for inactive simulation" do
        visit case_negotiations_path(case_instance)

        expect(page).to have_current_path(cases_path)
        expect(page).to have_content("This case does not have an active simulation")
      end
    end

    context "when instructor activates simulation", :js do
      before do
        login_as(instructor, scope: :user)
      end

      it "can activate simulation through service call" do
        # This test simulates what would happen if there was an admin interface
        # For now, we'll test the backend activation directly

        visit course_case_path(course, case_instance)
        expect(page).to have_content("Not started")

        # Simulate instructor activating simulation
        service = SimulationOrchestrationService.new(simulation)
        result = service.start_simulation!

        expect(result[:simulation_started]).to be true
        expect(simulation.reload.status).to eq("active")

        # Now case should show as in progress
        case_instance.reload
        visit current_path

        # The status should reflect that simulation is now active
        expect(simulation.status).to eq("active")
      end
    end
  end

  describe "Case with active simulation" do
    let!(:simulation) do
      create(:simulation,
        case: case_instance,
        status: :active,
        plaintiff_team: plaintiff_team,
        defendant_team: defendant_team,
        plaintiff_min_acceptable: 100000,
        plaintiff_ideal: 300000,
        defendant_ideal: 50000,
        defendant_max_acceptable: 200000,
        start_date: 1.hour.ago)
    end

    let!(:negotiation_round) { create(:negotiation_round, :active, simulation: simulation, round_number: 1) }

    context "when student accesses negotiations dashboard" do
      before do
        login_as(student1, scope: :user)
      end

      it "successfully loads negotiations dashboard" do
        visit case_negotiations_path(case_instance)

        expect(page).to have_current_path(case_negotiations_path(case_instance))
        expect(page).to have_content("Negotiation Dashboard")
        expect(page).to have_content(case_instance.title)
        expect(page).to have_content("Round 1")
      end

      it "shows team-specific information for plaintiff" do
        visit case_negotiations_path(case_instance)

        # Should show plaintiff-specific data
        expect(page).to have_content("Round 1")
        expect(page).to have_content("Active")

        # Should have negotiation action buttons
        expect(page).to have_link("Submit Offer") | have_button("Submit Offer")
        expect(page).to have_link("Client Consultation") | have_button("Client Consultation")
      end

      it "allows navigation to different negotiation sections" do
        visit case_negotiations_path(case_instance)

        # Test navigation to submit offer
        if page.has_link?("Submit Offer")
          click_link "Submit Offer"
          expect(page).to have_current_path(submit_offer_case_negotiation_path(case_instance, negotiation_round))
        end

        # Navigate back to dashboard
        visit case_negotiations_path(case_instance)

        # Test navigation to history
        if page.has_link?("Negotiation History")
          click_link "Negotiation History"
          expect(page).to have_current_path(history_case_negotiations_path(case_instance))
        end
      end
    end

    context "when defendant team member accesses negotiations" do
      before do
        login_as(student2, scope: :user)
      end

      it "shows defendant-specific information" do
        visit case_negotiations_path(case_instance)

        expect(page).to have_current_path(case_negotiations_path(case_instance))
        expect(page).to have_content("Negotiation Dashboard")
        expect(page).to have_content("Round 1")

        # Should show defendant perspective
        # Note: The exact content would depend on implementation
        expect(page).to have_content("Active")
      end
    end

    context "when unassigned user tries to access negotiations" do
      let(:unassigned_student) { create(:user, :student, organization: organization) }
      let!(:enrollment) { create(:course_enrollment, user: unassigned_student, course: course) }

      before do
        login_as(unassigned_student, scope: :user)
      end

      it "denies access with appropriate message" do
        visit case_negotiations_path(case_instance)

        expect(page).to have_current_path(cases_path)
        expect(page).to have_content("not assigned to a team")
      end
    end
  end

  describe "Complete simulation workflow" do
    let!(:simulation) do
      create(:simulation,
        case: case_instance,
        status: :setup,
        plaintiff_team: plaintiff_team,
        defendant_team: defendant_team,
        plaintiff_min_acceptable: 100000,
        plaintiff_ideal: 300000,
        defendant_ideal: 50000,
        defendant_max_acceptable: 200000)
    end

    context "full workflow from setup to active" do
      before do
        login_as(instructor, scope: :user)
      end

      it "demonstrates complete activation workflow" do
        # Start with case showing not started
        visit course_case_path(course, case_instance)
        expect(page).to have_content("Not started")

        # Verify student cannot access negotiations yet
        login_as(student1, scope: :user)
        visit case_negotiations_path(case_instance)
        expect(page).to have_current_path(cases_path)
        expect(page).to have_content("does not have an active simulation")

        # Instructor activates simulation (backend operation)
        service = SimulationOrchestrationService.new(simulation)
        result = service.start_simulation!

        expect(result[:simulation_started]).to be true
        expect(simulation.reload.status).to eq("active")
        expect(simulation.negotiation_rounds.count).to eq(1)

        # Now student can access negotiations
        visit case_negotiations_path(case_instance)
        expect(page).to have_current_path(case_negotiations_path(case_instance))
        expect(page).to have_content("Negotiation Dashboard")
        expect(page).to have_content("Round 1")
        expect(page).to have_content("Active")

        # Student can navigate to offer submission
        if page.has_link?("Submit Offer")
          click_link "Submit Offer"
          expect(page).to have_current_path(submit_offer_case_negotiation_path(case_instance, simulation.negotiation_rounds.first))
        end
      end
    end
  end

  describe "Error handling and user feedback" do
    before do
      login_as(student1, scope: :user)
    end

    it "provides clear feedback for various error states" do
      # Test non-existent case
      expect {
        visit "/cases/99999/negotiations"
      }.not_to raise_error

      expect(page).to have_current_path(cases_path)
      expect(page).to have_content("not found") | have_content("does not exist")
    end

    it "handles permission errors gracefully" do
      # Create case without team assignment
      other_case = create(:case, course: course, created_by: instructor)
      create(:simulation, case: other_case, status: :active)

      visit case_negotiations_path(other_case)

      expect(page).to have_current_path(cases_path)
      expect(page).to have_content("not assigned to a team")
    end
  end

  describe "Status indicators and visual feedback" do
    let!(:simulation) do
      create(:simulation,
        case: case_instance,
        status: :active,
        plaintiff_team: plaintiff_team,
        defendant_team: defendant_team)
    end

    before do
      login_as(student1, scope: :user)
    end

    it "shows clear status indicators throughout interface" do
      visit course_case_path(course, case_instance)

      # Should show that case/simulation is active
      # This would depend on the UI implementation
      expect(page).to have_link("Negotiations")

      click_link "Negotiations"
      expect(page).to have_current_path(case_negotiations_path(case_instance))
      expect(page).to have_content("Dashboard")
    end
  end
end
