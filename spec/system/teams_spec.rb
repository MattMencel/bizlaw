# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Teams page", type: :system do
  let(:instructor) { create(:user, :instructor) }
  let(:student) { create(:user, :student) }
  let(:course1) { create(:course, instructor: instructor, title: "Business Law 101", course_code: "BLAW-101") }
  let(:course2) { create(:course, instructor: instructor, title: "Contract Law", course_code: "CLAW-201") }

  before do
    # Set up course enrollments
    create(:course_enrollment, user: instructor, course: course1, status: "active")
    create(:course_enrollment, user: instructor, course: course2, status: "active")
    create(:course_enrollment, user: student, course: course1, status: "active")
  end

  context "when viewing as instructor" do
    let!(:team1) { create(:team, :with_members, owner: instructor, members_count: 3) }
    let!(:team2) { create(:team, :defendant, :with_members, owner: instructor, members_count: 2) }
    let!(:team3) { create(:team, owner: instructor) }

    before do
      # Associate teams with different courses
      team1.simulation.case.update!(course: course1)
      team2.simulation.case.update!(course: course1)
      team3.simulation.case.update!(course: course2)

      sign_in instructor
    end

    it "displays teams with hierarchical grouping by default" do
      visit teams_path

      expect(page).to have_content("Teams")
      expect(page).to have_content("Business Law 101")
      expect(page).to have_content("Contract Law")

      # Check team details are displayed with context
      expect(page).to have_content(team1.name)
      expect(page).to have_content(team2.name)
      expect(page).to have_content(team3.name)
    end

    it "displays team role badges" do
      visit teams_path

      within "[data-team-id='#{team1.id}']" do
        expect(page).to have_content("Plaintiff")
      end

      within "[data-team-id='#{team2.id}']" do
        expect(page).to have_content("Defendant")
      end
    end

    it "shows team member counts and capacity" do
      visit teams_path

      within "[data-team-id='#{team1.id}']" do
        expect(page).to have_content("3/5 members")
      end

      within "[data-team-id='#{team2.id}']" do
        expect(page).to have_content("2/5 members")
      end
    end

    it "displays course and simulation context" do
      visit teams_path

      # Should show course information in hierarchy
      expect(page).to have_content("BLAW-101")
      expect(page).to have_content("CLAW-201")

      # Should show case/simulation information
      expect(page).to have_content(team1.case.title)
      expect(page).to have_content(team1.simulation.display_name)
    end

    it "allows switching between view modes using tabs" do
      visit teams_path

      # Default hierarchical view
      expect(page).to have_selector(".tab-active", text: "By Course")

      # Switch to simulation view
      click_on "By Simulation"
      expect(page).to have_selector(".tab-active", text: "By Simulation")

      # Switch to all teams view
      click_on "All Teams"
      expect(page).to have_selector(".tab-active", text: "All Teams")
    end

    it "supports filtering by course" do
      visit teams_path

      # Apply course filter
      select "Business Law 101", from: "course_filter"
      click_button "Apply Filters"

      expect(page).to have_content(team1.name)
      expect(page).to have_content(team2.name)
      expect(page).not_to have_content(team3.name)
    end

    it "supports filtering by role" do
      visit teams_path

      # Apply role filter
      select "Defendant", from: "role_filter"
      click_button "Apply Filters"

      expect(page).to have_content(team2.name)
      expect(page).not_to have_content(team1.name)
      expect(page).not_to have_content(team3.name)
    end

    it "provides quick action buttons for teams" do
      visit teams_path

      within "[data-team-id='#{team1.id}']" do
        expect(page).to have_link("View Team")
        expect(page).to have_link("View Simulation")
        expect(page).to have_link("View Course")
      end
    end
  end

  context "when viewing as student" do
    let!(:student_team) { create(:team, owner: student) }
    let!(:instructor_team) { create(:team, owner: instructor) }

    before do
      # Associate with course1
      student_team.simulation.case.update!(course: course1)
      instructor_team.simulation.case.update!(course: course1)

      # Make student a member of their team
      create(:team_member, team: student_team, user: student)

      sign_in student
    end

    it "only shows teams where student is a member" do
      visit teams_path

      expect(page).to have_content(student_team.name)
      expect(page).not_to have_content(instructor_team.name)
    end

    it "shows simplified view for students" do
      visit teams_path

      # Students should see flat list, not hierarchical by default
      expect(page).to have_content("Teams")
      expect(page).to have_content(student_team.name)
    end
  end

  context "accessibility" do
    let!(:team) { create(:team, owner: instructor) }

    before do
      team.simulation.case.update!(course: course1)
      sign_in instructor
    end

    it "meets accessibility standards", :accessibility do
      visit teams_path
      expect(page).to be_axe_clean
    end

    it "has proper ARIA labels and roles" do
      visit teams_path

      expect(page).to have_selector("[role='tablist']")
      expect(page).to have_selector("[role='tab']")
      expect(page).to have_selector("[role='tabpanel']")
    end

    it "supports keyboard navigation" do
      visit teams_path

      # Tab through the interface
      find("body").send_keys(:tab)
      expect(page).to have_selector(":focus")
    end
  end
end
