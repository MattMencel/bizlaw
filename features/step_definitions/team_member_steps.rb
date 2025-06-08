# frozen_string_literal: true

# Step definitions for team member management features

Given("the following users exist:") do |table|
  table.hashes.each do |user_data|
    create(:user,
           name: user_data['Name'],
           email: user_data['Email'],
           role: user_data['Role']&.downcase || 'student',
           confirmed_at: Time.current)
  end
end

Given("the following teams exist:") do |table|
  table.hashes.each do |team_data|
    owner = User.find_by(email: team_data['Owner']) if team_data['Owner']
    create(:team,
           name: team_data['Name'],
           description: team_data['Description'],
           owner: owner,
           max_members: team_data['Max Members']&.to_i || 5)
  end
end

Given("the following team memberships exist:") do |table|
  table.hashes.each do |membership_data|
    user = User.find_by!(email: membership_data['User'])
    team = Team.find_by!(name: membership_data['Team'])
    role = membership_data['Role']&.downcase || 'member'

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

When("I add {string} as a member to {string}") do |user_email, team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)

  if page.has_link?('Add Member')
    click_link 'Add Member'
  elsif page.has_button?('Add Member')
    click_button 'Add Member'
  else
    # Navigate to add member form
    visit new_team_team_member_path(team)
  end

  fill_in 'Email', with: user_email
  click_button 'Add Member'
end

When("I add {string} as a {string} to {string}") do |user_email, role, team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)

  click_link 'Add Member'
  fill_in 'Email', with: user_email
  select role.capitalize, from: 'Role' if page.has_select?('Role')
  click_button 'Add Member'
end

When("I remove {string} from {string}") do |user_email, team_name|
  team = Team.find_by!(name: team_name)
  user = User.find_by!(email: user_email)

  visit team_path(team)

  # Find the member row and click remove
  within("[data-user-id='#{user.id}']") do
    click_link 'Remove'
  end

  # Confirm removal if there's a confirmation dialog
  click_button 'Confirm' if page.has_button?('Confirm')
end

When("I change the role of {string} to {string}") do |user_email, new_role|
  user = User.find_by!(email: user_email)

  # Find the member row and edit role
  within("[data-user-id='#{user.id}']") do
    if page.has_link?('Edit')
      click_link 'Edit'
    elsif page.has_select?('Role')
      select new_role.capitalize, from: 'Role'
    end
  end

  # Save changes if there's a save button
  click_button 'Save' if page.has_button?('Save')
end

When("I try to add myself to {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)

  click_link 'Join Team' if page.has_link?('Join Team')
end

When("I try to leave {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)

  click_link 'Leave Team' if page.has_link?('Leave Team')
end

When("I try to remove myself from {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  visit team_path(team)

  within("[data-user-id='#{@current_user.id}']") do
    click_link 'Remove'
  end
end

When("I navigate to the team members page for {string}") do |team_name|
  team = Team.find_by!(name: team_name)
  visit team_team_members_path(team)
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
  expect(page.current_path).to match(%r{/teams/[\w-]+})
end

Then("the team should have {int} members") do |member_count|
  members = page.all('[data-role="team-member"]')
  expect(members.count).to eq(member_count)
end

Then("I should see the team member management interface") do
  expect(page).to have_content('Team Members')
  expect(page).to have_link('Add Member') if can_manage_team?
end

Then("I should not see the add member button") do
  expect(page).not_to have_link('Add Member')
  expect(page).not_to have_button('Add Member')
end

Then("I should not see the remove member options") do
  expect(page).not_to have_link('Remove')
  expect(page).not_to have_button('Remove')
end

# Helper method to check if current user can manage team
def can_manage_team?
  return true if @current_user&.admin?
  return true if @current_user&.instructor?

  # Check if user is team owner or manager
  false # This would need actual policy checking
end
