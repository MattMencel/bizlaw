# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Team Member Basic E2E", type: :system do
  let(:organization) { create(:organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:course) { create(:course, instructor: instructor, organization: organization) }
  let(:team) { create(:team, course: course) }

  let!(:student1) { create(:user, organization: organization, first_name: "Alice", last_name: "Cooper") }
  let!(:student2) { create(:user, organization: organization, first_name: "Bob", last_name: "Dylan") }

  before do
    # Enroll students in the course
    create(:course_enrollment, user: student1, course: course, status: "active")
    create(:course_enrollment, user: student2, course: course, status: "active")
  end

  describe "Team member addition", :js do
    it "can add a team member with Turbo Streams" do
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
