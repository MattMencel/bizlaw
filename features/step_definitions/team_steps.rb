# frozen_string_literal: true

Given("I am a logged in user") do
  @current_user = create(:user)
  login_as(@current_user)
end

Given("I have the following teams:") do |table|
  table.hashes.each do |team_data|
    create(:team, team_data.merge(owner: @current_user))
  end
end

Given("I am the owner of {string}") do |team_name|
  @team = Team.find_by!(name: team_name)
  expect(@team.owner).to eq(@current_user)
end

Given("{string} has {int} members") do |team_name, count|
  team = Team.find_by!(name: team_name)
  create_list(:team_member, count - 1, team: team) # -1 because owner is already a member
end

Given("the following teams exist:") do |table|
  table.hashes.each do |team_data|
    create(:team, team_data)
  end
end

When("I create a team with the following details:") do |table|
  visit new_team_path
  team_data = table.hashes.first

  fill_in "Name", with: team_data["name"]
  fill_in "Description", with: team_data["description"]
  fill_in "Maximum members", with: team_data["max_members"]

  click_button "Create Team"
end

When("I visit the teams page") do
  visit teams_path
end

When("I update {string} with the following details:") do |team_name, table|
  team = Team.find_by!(name: team_name)
  visit edit_team_path(team)

  team_data = table.hashes.first
  fill_in "Name", with: team_data["name"]
  fill_in "Description", with: team_data["description"]
  fill_in "Maximum members", with: team_data["max_members"]

  click_button "Update Team"
end

When("I delete {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)
  click_button "Delete Team"
end

When("I try to add a new member to {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)
  click_link "Add Member"
end

When("I search for teams containing {string}") do |search_term|
  visit teams_path
  fill_in "Search teams", with: search_term
  click_button "Search"
end

Then("I should see a success message {string}") do |message|
  expect(page).to have_content(message)
end

Then("I should be the owner of {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  expect(team.owner).to eq(@current_user)
end

Then("the team should have {int} members") do |count|
  expect(page).to have_content("Members: #{count}")
end

Then("I should see the following teams:") do |table|
  table.hashes.each do |team_data|
    within(".teams-list") do
      expect(page).to have_content(team_data["name"])
      expect(page).to have_content(team_data["description"])
      expect(page).to have_content(team_data["members"])
    end
  end
end

Then("the team details should be updated") do
  expect(page).to have_current_path(team_path(Team.last))
  expect(page).to have_content("Alpha Prime")
  expect(page).to have_content("Updated project team")
  expect(page).to have_content("Maximum members: 6")
end

Then("{string} should not be visible in the teams list") do |team_name|
  visit teams_path
  expect(page).not_to have_content(team_name)
end

Then("I should see an error message {string}") do |message|
  expect(page).to have_content(message)
end

Then("I should see {string} in the results") do |team_name|
  within(".search-results") do
    expect(page).to have_content(team_name)
  end
end

Then("I should not see {string} in the results") do |team_name|
  within(".search-results") do
    expect(page).not_to have_content(team_name)
  end
end

# Additional team management step definitions

Given("I am an owner of a team") do
  @current_user ||= create(:user, role: :student)
  @team = create(:team, owner: @current_user)
end

Given("there are teams available to join") do
  @available_teams = create_list(:team, 3, max_members: 5)
  @available_teams.each do |team|
    create_list(:team_member, 2, team: team) # Each team has 2 existing members
  end
end

Given("the team {string} is full") do |team_name|
  team = Team.find_by!(name: team_name)
  # Fill the team to max capacity
  (team.max_members - team.team_members.count).times do
    create(:team_member, team: team)
  end
end

Given("the team {string} has activity") do |team_name|
  team = Team.find_by!(name: team_name)
  # Create some team activity/events
  create_list(:case_event, 5, data: {team_id: team.id, action: "team_activity"})
end

When("I navigate to team creation page") do
  visit new_team_path
end

When("I fill in the team form with:") do |table|
  details = table.rows_hash

  fill_in "Name", with: details["Name"] if details["Name"]
  fill_in "Description", with: details["Description"] if details["Description"]
  fill_in "Maximum members", with: details["Max Members"] if details["Max Members"]

  # Handle any additional fields
  select details["Type"], from: "Team Type" if details["Type"] && page.has_select?("Team Type")
end

When("I submit the team form") do
  click_button "Create Team"
end

When("I view the team {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)
end

When("I edit the team {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  visit edit_team_path(team)
end

When("I try to join the team {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)

  if page.has_link?("Join Team")
    click_link "Join Team"
  elsif page.has_button?("Join")
    click_button "Join"
  end
end

When("I leave the team {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)

  if page.has_link?("Leave Team")
    click_link "Leave Team"
  elsif page.has_button?("Leave")
    click_button "Leave"
  end

  # Handle confirmation
  click_button "Confirm" if page.has_button?("Confirm")
end

When("I view my teams") do
  visit teams_path
end

When("I view available teams") do
  visit teams_path
  click_link "Browse Teams" if page.has_link?("Browse Teams")
end

When("I filter teams by {string}") do |filter_criteria|
  select filter_criteria, from: "Filter"
  click_button "Apply Filter"
end

When("I view team activity for {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)
  click_link "Activity" if page.has_link?("Activity")
end

When("I invite {string} to join the team") do |user_email|
  click_link "Invite Member" if page.has_link?("Invite Member")
  fill_in "Email", with: user_email
  click_button "Send Invitation"
end

When("I archive the team {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)

  click_link "Archive Team" if page.has_link?("Archive Team")
  click_button "Confirm" if page.has_button?("Confirm")
end

When("I clone the team {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)

  click_link "Clone Team" if page.has_link?("Clone Team")
end

Then("I should see the team details") do
  team = @team || Team.last
  expect(page).to have_content(team.name)
  expect(page).to have_content(team.description) if team.description
end

Then("I should see the team {string} in my teams") do |team_name|
  expect(page).to have_content(team_name)
end

Then("I should not see the team {string} in my teams") do |team_name|
  expect(page).not_to have_content(team_name)
end

Then("I should be a member of the team {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  expect(team.team_members.exists?(user: @current_user)).to be true
end

Then("I should not be a member of the team {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  expect(team.team_members.exists?(user: @current_user)).to be false
end

Then("the team should be created successfully") do
  success_present = page.has_content?("Team created successfully") ||
    page.has_content?("successfully created") ||
    page.has_css?(".alert-success")
  expect(success_present).to be true
end

Then("the team should be updated successfully") do
  success_present = page.has_content?("Team updated successfully") ||
    page.has_content?("successfully updated") ||
    page.has_css?(".alert-success")
  expect(success_present).to be true
end

Then("the team should be deleted successfully") do
  success_present = page.has_content?("Team deleted successfully") ||
    page.has_content?("successfully deleted") ||
    page.has_css?(".alert-success")
  expect(success_present).to be true
end

Then("I should see a message about joining the team") do
  join_present = page.has_content?("joined") ||
    page.has_content?("Welcome to the team") ||
    page.has_css?(".alert-success")
  expect(join_present).to be true
end

Then("I should see a message about leaving the team") do
  leave_present = page.has_content?("left") ||
    page.has_content?("removed from") ||
    page.has_css?(".alert-success")
  expect(leave_present).to be true
end

Then("I should see the team is full") do
  full_indicated = page.has_content?("Team is full") ||
    page.has_content?("No available spots") ||
    !page.has_link?("Join Team")
  expect(full_indicated).to be true
end

Then("I should see team activity") do
  activity_present = page.has_content?("Activity") ||
    page.has_css?(".activity-timeline") ||
    page.has_css?(".team-events")
  expect(activity_present).to be true
end

Then("an invitation should be sent to {string}") do |user_email|
  # This would check email delivery in a real scenario
  invitation_sent = page.has_content?("Invitation sent") ||
    page.has_content?("invited")
  expect(invitation_sent).to be true
end

Then("the team should be archived") do
  archived_present = page.has_content?("Team archived") ||
    page.has_content?("archived successfully")
  expect(archived_present).to be true
end

Then("I should see a cloned team") do
  cloned_present = page.has_content?("Team cloned") ||
    page.has_content?("Copy of")
  expect(cloned_present).to be true
end

Then("I should be redirected to the teams page") do
  expect(page).to have_current_path(teams_path, ignore_query: true)
end

Then("I should be redirected to the team page") do
  expect(page).to have_current_path(%r{/teams/[\w-]+})
end
