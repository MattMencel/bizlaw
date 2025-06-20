# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Team Member Bulk Operations", type: :system do
  let(:organization) { create(:organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:course) { create(:course, instructor: instructor, organization: organization) }
  let(:team) { create(:team, course: course, owner: instructor) }

  let!(:student1) { create(:user, organization: organization, first_name: "Alice", last_name: "Cooper") }
  let!(:student2) { create(:user, organization: organization, first_name: "Bob", last_name: "Dylan") }
  let!(:student3) { create(:user, organization: organization, first_name: "Charlie", last_name: "Parker") }

  before do
    driven_by :rack_test

    # Enroll students in the course
    create(:course_enrollment, user: student1, course: course, status: "active")
    create(:course_enrollment, user: student2, course: course, status: "active")
    create(:course_enrollment, user: student3, course: course, status: "active")

    sign_in instructor
  end

  describe "bulk adding members" do
    it "allows selecting multiple students and adding them at once" do
      visit team_path(team)

      expect(page).to have_content("Team Members")
      click_link "Add Members"

      expect(page).to have_content("Add Team Members")
      expect(page).to have_content("Select Students")

      # Select multiple students
      check "user_ids_#{student1.id}"
      check "user_ids_#{student2.id}"

      select "Member", from: "role"
      click_button "Add Selected Members"

      expect(page).to have_content("Successfully added 2 team members")
      expect(page).to have_content("Alice Cooper")
      expect(page).to have_content("Bob Dylan")
    end

    it "shows validation error when no students selected" do
      visit team_path(team)
      click_link "Add Members"

      click_button "Add Selected Members"

      expect(page).to have_content("Please select at least one student")
    end
  end

  describe "bulk removing members" do
    let!(:member1) { create(:team_member, team: team, user: student1, role: "member") }
    let!(:member2) { create(:team_member, team: team, user: student2, role: "member") }

    it "allows selecting multiple members and removing them at once" do
      visit team_path(team)

      expect(page).to have_content("Alice Cooper")
      expect(page).to have_content("Bob Dylan")

      # Select members to remove
      check "member_ids_#{member1.id}"
      check "member_ids_#{member2.id}"

      click_button "Remove Selected"

      expect(page).to have_content("Successfully removed 2 team members")
      expect(page).not_to have_content("Alice Cooper")
      expect(page).not_to have_content("Bob Dylan")
    end
  end

  describe "select all/none functionality" do
    it "works for adding members" do
      visit team_path(team)
      click_link "Add Members"

      # Initially no checkboxes checked
      expect(page).to have_unchecked_field("user_ids_#{student1.id}")
      expect(page).to have_unchecked_field("user_ids_#{student2.id}")

      # Click Select All
      click_button "Select All"

      expect(page).to have_checked_field("user_ids_#{student1.id}")
      expect(page).to have_checked_field("user_ids_#{student2.id}")

      # Click Select None
      click_button "Select None"

      expect(page).to have_unchecked_field("user_ids_#{student1.id}")
      expect(page).to have_unchecked_field("user_ids_#{student2.id}")
    end
  end

  describe "page without real-time refresh" do
    it "does not have auto-refresh components" do
      visit team_path(team)

      # Verify no real-time controllers present
      expect(page).not_to have_selector("[data-controller='real-time']")
      expect(page).not_to have_selector("[data-real-time-refresh-interval-value]")

      # Verify no Recent Activity section
      expect(page).not_to have_content("Recent Activity")
    end
  end
end
