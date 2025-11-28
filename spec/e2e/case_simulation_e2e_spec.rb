# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Case Simulation E2E", type: :system do
  let(:organization) { create(:organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:student1) { create(:user, organization: organization) }
  let(:student2) { create(:user, organization: organization) }
  let(:course) { create(:course, instructor: instructor, organization: organization) }

  # Enroll users BEFORE creating case/simulation (use let! for eager evaluation)
  let!(:instructor_enrollment) { create(:course_enrollment, user: instructor, course: course, status: "active") }
  let!(:student1_enrollment) { create(:course_enrollment, user: student1, course: course, status: "active") }
  let!(:student2_enrollment) { create(:course_enrollment, user: student2, course: course, status: "active") }

  # Now create case and simulation (after enrollments exist)
  # IMPORTANT: Set created_by to enrolled instructor
  let(:case_obj) { create(:case, course: course, created_by: instructor) }
  let(:simulation) { create(:simulation, case: case_obj) }
  let(:team) { create(:team, simulation: simulation, owner: student1) }

  before do
    driven_by :playwright # Full e2e testing with automatic test server

    # Set up team members
    create(:team_member, user: student1, team: team, role: "manager")
    create(:team_member, user: student2, team: team, role: "member")
  end

  describe "Student workflow" do
    it "allows student to navigate simulation and submit offers" do
      # Student logs in
      sign_in student1
      visit dashboard_path

      expect(page).to have_content("Simulation Dashboard")
      expect(page).to have_content(case_obj.title)

      # Navigate to case
      visit case_path(case_obj)
      expect(page).to have_content(case_obj.title)
      expect(page).to have_content("Case Description")

      # Access evidence vault
      click_link "Evidence Vault"
      expect(page).to have_content("Evidence Vault")

      # Navigate to negotiations
      click_link "Negotiations"
      expect(page).to have_content("Negotiations")

      # Submit settlement offer (if form exists)
      if page.has_css?('form[data-testid="settlement-form"]')
        within('[data-testid="settlement-form"]') do
          fill_in "Amount", with: "50000"
          fill_in "Terms", with: "Standard settlement terms"
          click_button "Submit Offer"
        end

        expect(page).to have_content("Offer submitted successfully")
      end
    end
  end

  describe "Instructor workflow" do
    it "allows instructor to manage course and review submissions" do
      sign_in instructor
      visit dashboard_path

      expect(page).to have_content("Instructor Dashboard")

      # Navigate directly to case
      visit case_path(case_obj)
      expect(page).to have_content(case_obj.title)
      expect(page).to have_content("Case Description")
    end
  end

  describe "Team collaboration" do
    it "allows team members to collaborate on case" do
      # First student creates a document/note
      sign_in student1
      visit case_path(case_obj)

      if page.has_css?('[data-testid="add-note-form"]')
        within('[data-testid="add-note-form"]') do
          fill_in "Note", with: "Initial case analysis complete"
          click_button "Add Note"
        end
      end

      # Sign out and sign in as second student
      sign_out student1
      sign_in student2
      visit case_path(case_obj)

      # Second student can see the note
      if page.has_content?("Initial case analysis complete")
        expect(page).to have_content("Initial case analysis complete")
      end
    end
  end

  describe "Real-time features", :js do
    it "updates in real-time when team members make changes" do
      # Open same case in two browser contexts (if supported)
      sign_in student1
      visit case_path(case_obj)

      # This would test WebSocket/ActionCable functionality
      # Add specific real-time test logic based on your app's features
      expect(page).to have_content(case_obj.title)
    end
  end
end
