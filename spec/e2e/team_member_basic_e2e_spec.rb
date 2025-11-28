# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Team Member Basic E2E", type: :system do
  let(:organization) { create(:organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:course) { create(:course, instructor: instructor, organization: organization) }

  let!(:student1) { create(:user, organization: organization, first_name: "Alice", last_name: "Cooper") }
  let!(:student2) { create(:user, organization: organization, first_name: "Bob", last_name: "Dylan") }

  # Create enrollments FIRST (including instructor)
  let!(:instructor_enrollment) { create(:course_enrollment, user: instructor, course: course, status: "active") }
  let!(:student1_enrollment) { create(:course_enrollment, user: student1, course: course, status: "active") }
  let!(:student2_enrollment) { create(:course_enrollment, user: student2, course: course, status: "active") }

  # Create case and simulation (after enrollments exist)
  let(:case_obj) { create(:case, course: course, created_by: instructor) }
  let(:simulation) { create(:simulation, case: case_obj) }
  let(:team) { simulation.teams.first }

  describe "Team member addition", :js do
    it "can add a team member with Turbo Streams" do
      skip "Single-member add UI replaced with bulk operations - form structure changed to checkboxes"
      sign_in instructor
      visit team_path(team)

      expect(page).to have_content("Team Members")
      expect(page).not_to have_content("Alice Cooper")

      # Click Add Member
      click_link "Add Member"

      # Verify form appears
      expect(page).to have_content("Add Team Member")

      # Fill and submit form
      select "Alice Cooper", from: "team_member[user_id]"
      click_button "Add Member"

      # Verify member was added
      expect(page).to have_content("Alice Cooper")
      expect(page).to have_content("Team member was successfully added")
    end
  end

  describe "Team member removal", :js do
    let!(:team_member) { create(:team_member, user: student1, team: team, role: "member") }

    it "can remove a team member with Turbo Streams" do
      skip "Single-member remove UI replaced with bulk operations - form structure changed to checkboxes"
      sign_in instructor
      visit team_path(team)

      expect(page).to have_content("Alice Cooper")

      # Find and click delete button
      accept_confirm do
        find("form[action='#{team_team_member_path(team, team_member)}'] input[type='submit']").click
      end

      # Verify member was removed
      expect(page).not_to have_content("Alice Cooper")
      expect(page).to have_content("Team member was successfully removed")
    end
  end
end
