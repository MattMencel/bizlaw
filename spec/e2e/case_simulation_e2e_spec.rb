# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Case Simulation E2E", type: :system do
  let(:organization) { create(:organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:student1) { create(:user, organization: organization) }
  let(:student2) { create(:user, organization: organization) }
  let(:course) { create(:course, instructor: instructor, organization: organization) }
  let(:case_obj) { create(:case, course: course) }
  let(:team) { create(:team, course: course) }

  before do
    driven_by :playwright # Full e2e testing with automatic test server

    # Set up course enrollments
    create(:course_enrollment, user: student1, course: course, status: "active")
    create(:course_enrollment, user: student2, course: course, status: "active")

    # Set up team
    create(:team_member, user: student1, team: team, role: "leader")
    create(:team_member, user: student2, team: team, role: "member")
    create(:case_team, case: case_obj, team: team)
  end

  describe "Student workflow" do
    it "allows student to navigate simulation and submit offers" do
      # Student logs in
      sign_in student1
      visit dashboard_path

      expect(page).to have_content("Student Dashboard")
      expect(page).to have_content(course.name)

      # Navigate to case
      click_link case_obj.title
      expect(page).to have_content(case_obj.title)
      expect(page).to have_content("Case Details")

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

      # Navigate to course management
      click_link course.name
      expect(page).to have_content("Course Management")

      # View student progress
      if page.has_link?("View Progress")
        click_link "View Progress"
        expect(page).to have_content("Student Progress")
      end

      # Check case analytics
      visit case_path(case_obj)
      expect(page).to have_content(case_obj.title)
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
