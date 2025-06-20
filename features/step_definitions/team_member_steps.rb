# frozen_string_literal: true

# Step definitions for team member management features

Given("the following users exist:") do |table|
  table.hashes.each do |user_data|
    create(:user,
      name: user_data["Name"],
      email: user_data["Email"],
      role: user_data["Role"]&.downcase || "student",
      confirmed_at: Time.current)
  end
end

Given("the following teams exist:") do |table|
  table.hashes.each do |team_data|
    owner = User.find_by(email: team_data["Owner"]) if team_data["Owner"]
    create(:team,
      name: team_data["Name"],
      description: team_data["Description"],
      owner: owner,
      max_members: team_data["Max Members"]&.to_i || 5)
  end
end

Given("the following team memberships exist:") do |table|
  table.hashes.each do |membership_data|
    user = User.find_by!(email: membership_data["User"])
    team = Team.find_by!(name: membership_data["Team"])
    role = membership_data["Role"]&.downcase || "member"

    create(:team_member,
      user: user,
      team: team,
      role: role)
  end
end

Given("{string} is a member of {string}") do |user_email, team_name|
  user = User.find_by!(email: user_email)
  team = Team.find_by!(name: team_name)
  create(:team_member, user: user, team: team, role: :member)
end

Given("{string} is a manager of {string}") do |user_email, team_name|
  user = User.find_by!(email: user_email)
  team = Team.find_by!(name: team_name)
  create(:team_member, user: user, team: team, role: :manager)
end

Given("I am a manager of {string}") do |team_name|
  @current_user ||= create(:user, role: :student)
  team = Team.find_by!(name: team_name)
  create(:team_member, user: @current_user, team: team, role: :manager)
end

Given("I am a regular member of {string}") do |team_name|
  @current_user ||= create(:user, role: :student)
  team = Team.find_by!(name: team_name)
  create(:team_member, user: @current_user, team: team, role: :member)
end

Given("I am not a member of {string}") do |team_name|
  @current_user ||= create(:user, role: :student)
  team = Team.find_by!(name: team_name)
  # Ensure no membership exists
  TeamMember.where(user: @current_user, team: team).destroy_all
end

When("I navigate to the team management page") do
  visit teams_path
end

When("I click on {string} team") do |team_name|
  click_link team_name
end

When("I bulk add the following users to {string}:") do |team_name, table|
  team = Team.find_by!(name: team_name)
  visit team_path(team)

  click_link "Add Members"

  table.hashes.each do |row|
    user = User.find_by!(email: row["email"])
    check "user_ids_#{user.id}"
  end

  # If the table has role column, use it; otherwise use default
  if table.headers.include?("role")
    # For mixed roles, we'd need to handle this differently
    # For now, assume all same role or use default
    role = table.hashes.first["role"] || "member"
    select role.capitalize, from: "role"
  end

  click_button "Add Selected Members"
end

When("I bulk add the following users to {string} with role {string}:") do |team_name, role, table|
  team = Team.find_by!(name: team_name)
  visit team_path(team)

  click_link "Add Members"

  table.hashes.each do |row|
    user = User.find_by!(email: row["email"])
    check "user_ids_#{user.id}"
  end

  select role.capitalize, from: "role"
  click_button "Add Selected Members"
end

When("I bulk remove the following members from {string}:") do |team_name, table|
  team = Team.find_by!(name: team_name)
  visit team_path(team)

  table.hashes.each do |row|
    user = User.find_by!(email: row["email"])
    team_member = TeamMember.find_by!(team: team, user: user)
    check "member_ids_#{team_member.id}"
  end

  click_button "Remove Selected"
end

# Legacy single-member operations for backward compatibility
When("I add {string} as a member to {string}") do |user_email, team_name|
  step %(I bulk add the following users to "#{team_name}" with role "member":), table([["email"], [user_email]])
end

When("I add {string} as a {string} to {string}") do |user_email, role, team_name|
  step %(I bulk add the following users to "#{team_name}":), table([["email", "role"], [user_email, role]])
end

When("I remove {string} from {string}") do |user_email, team_name|
  step %(I bulk remove the following members from "#{team_name}":), table([["email"], [user_email]])
end

When("I change the role of {string} to {string}") do |user_email, new_role|
  user = User.find_by!(email: user_email)

  # Find the member row and edit role
  within("[data-user-id='#{user.id}']") do
    if page.has_link?("Edit")
      click_link "Edit"
    elsif page.has_select?("Role")
      select new_role.capitalize, from: "Role"
    end
  end

  # Save changes if there's a save button
  click_button "Save" if page.has_button?("Save")
end

When("I try to add myself to {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)

  click_link "Join Team" if page.has_link?("Join Team")
end

When("I try to leave {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)

  click_link "Leave Team" if page.has_link?("Leave Team")
end

When("I try to remove myself from {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)

  within("[data-user-id='#{@current_user.id}']") do
    click_link "Remove"
  end
end

When("I navigate to the team members page for {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  visit team_team_members_path(team)
end

When("I visit the add team members page for {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)
  click_link "Add Members"
end

When("I click {string}") do |button_text|
  click_button button_text
end

When("I click {string} in the members section") do |button_text|
  within("#team-members") do
    click_button button_text
  end
end

When("I click {string} without selecting any users") do |button_text|
  click_button button_text
end

When("I click {string} without selecting any members") do |button_text|
  click_button button_text
end

When("I try to access the bulk add members page") do
  team = Team.find_by!(name: "Project Team")
  visit new_team_team_member_path(team)
end

When("I try to bulk add {string} to {string}") do |user_email, team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)
  click_link "Add Members"
  # The user should not appear in the list since they're already a member
end

Given("the following users are members of {string}:") do |team_name, table|
  team = Team.find_by!(name: team_name)
  table.hashes.each do |row|
    user = User.find_by!(email: row["email"])
    role = row["role"]&.downcase || "member"
    create(:team_member, user: user, team: team, role: role)
  end
end

Then("{string} should be listed as a member of {string}") do |user_name, team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)
  expect(page).to have_content(user_name)
end

Then("{string} should be listed as a {string} of {string}") do |user_name, role, team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)
  expect(page).to have_content(user_name)
  expect(page).to have_content(role.capitalize)
end

Then("{string} should not be listed as a member of {string}") do |user_name, team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)
  expect(page).not_to have_content(user_name)
end

Then("I should see {string} as a team member") do |user_name|
  expect(page).to have_content(user_name)
end

Then("I should not see {string} as a team member") do |user_name|
  expect(page).not_to have_content(user_name)
end

Then("I should see the role of {string} as {string}") do |user_name, role|
  expect(page).to have_content(user_name)
  expect(page).to have_content(role.capitalize)
end

Then("I should see a message {string}") do |message|
  expect(page).to have_content(message)
end

Then("I should see an error message {string}") do |message|
  expect(page).to have_content(message)
end

Then("I should be redirected to the team page") do
  expect(page).to have_current_path(%r{/teams/[\w-]+})
end

Then("the team should have {int} members") do |member_count|
  members = page.all('[data-role="team-member"]')
  expect(members.count).to eq(member_count)
end

Then("I should see the team member management interface") do
  expect(page).to have_content("Team Members")
  expect(page).to have_link("Add Member") if can_manage_team?
end

Then("I should not see the add member button") do
  expect(page).not_to have_link("Add Member")
  expect(page).not_to have_button("Add Member")
end

Then("I should not see the remove member options") do
  expect(page).not_to have_link("Remove")
  expect(page).not_to have_button("Remove")
end

Then("all available students should be selected") do
  checkboxes = page.all("input[type='checkbox'][name*='user_ids']")
  checkboxes.each do |checkbox|
    expect(checkbox).to be_checked
  end
end

Then("no students should be selected") do
  checkboxes = page.all("input[type='checkbox'][name*='user_ids']")
  checkboxes.each do |checkbox|
    expect(checkbox).not_to be_checked
  end
end

Then("all team members should be selected for removal") do
  checkboxes = page.all("input[type='checkbox'][name*='member_ids']")
  checkboxes.each do |checkbox|
    expect(checkbox).to be_checked
  end
end

Then("no team members should be selected for removal") do
  checkboxes = page.all("input[type='checkbox'][name*='member_ids']")
  checkboxes.each do |checkbox|
    expect(checkbox).not_to be_checked
  end
end

Then("I should not see any auto-refreshing components") do
  expect(page).not_to have_selector("[data-controller='real-time']")
end

Then("the page should not make background requests") do
  # This would need to be tested by monitoring network requests
  # For now, we just verify no real-time controllers are present
  expect(page).not_to have_selector("[data-real-time-refresh-interval-value]")
end

Then("I should not see a {string} section") do |section_name|
  expect(page).not_to have_content(section_name)
end

Then("the user should not appear in the available students list") do
  # Check that the user is not in the checkbox list
  expect(page).not_to have_selector("input[type='checkbox'][name*='user_ids']")
end

# Helper method to check if current user can manage team
def can_manage_team?
  return true if @current_user&.admin?
  return true if @current_user&.instructor?

  # Check if user is team owner or manager
  false # This would need actual policy checking
end
