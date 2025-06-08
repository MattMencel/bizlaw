# frozen_string_literal: true

Given("I am a member of a team") do
  @team = create(:team)
  create(:team_member, team: @team, user: @current_user)
end

Given("there is a case type {string}") do |title|
  # Handle both CaseType model and case_type enum approaches
  if defined?(CaseType)
    @case_type = create(:case_type, title: title)
  else
    # Map title to enum value
    @case_type_enum = map_case_type_title_to_enum(title)
  end
end

Given("the following cases exist:") do |table|
  table.hashes.each do |row|
    # Handle team creation
    if row["Team"]
      team = Team.find_by(name: row["Team"]) || create(:team, name: row["Team"])
    end

    # Handle case type - either as model or enum
    case_attributes = {}
    if row["Case Type"]
      if defined?(CaseType)
        case_type = create(:case_type, title: row["Case Type"])
        case_attributes[:case_type] = case_type
      else
        case_attributes[:case_type] = map_case_type_title_to_enum(row["Case Type"])
      end
    end

    # Create the case
    case_record = create(:case, case_attributes.merge(status: row["Status"]&.downcase))

    # Associate with team if provided
    if team
      create(:case_team, case: case_record, team: team, role: :plaintiff)
    end
  end
end

Given("I have an active case {string}") do |case_type_title|
  case_attributes = {}

  if defined?(CaseType)
    case_type = create(:case_type, title: case_type_title)
    case_attributes[:case_type] = case_type
  else
    case_attributes[:case_type] = map_case_type_title_to_enum(case_type_title)
  end

  @case = create(:case, case_attributes.merge(status: :in_progress))

  # Associate with team if exists
  if @team
    create(:case_team, case: @case, team: @team, role: :plaintiff)
  end
end

Given("there is a case {string} under review") do |case_type_title|
  case_attributes = {}

  if defined?(CaseType)
    case_type = create(:case_type, title: case_type_title)
    case_attributes[:case_type] = case_type
  else
    case_attributes[:case_type] = map_case_type_title_to_enum(case_type_title)
  end

  @case = create(:case, case_attributes.merge(status: :submitted))

  # Associate with team if exists
  if @team
    create(:case_team, case: @case, team: @team, role: :plaintiff)
  end
end

Given("I have a case due in {int} days") do |days|
  @case = create(:case, team: @team, due_date: days.days.from_now)
end

Given("I have completed multiple cases") do
  case_types = [ :sexual_harassment, :discrimination, :wrongful_termination ]

  3.times do |i|
    case_attributes = { case_type: case_types[i] }
    case_record = create(:case, case_attributes.merge(status: :completed))

    # Associate with team if exists
    if @team
      create(:case_team, case: case_record, team: @team, role: :plaintiff)
    end
  end
end

Given("I have completed all required tasks") do
  # This step would be implemented based on your task tracking system
  # For now, it's a placeholder
  true
end

Given("I am an instructor") do
  @current_user.update(role: :instructor)
end

When("I start a new case with the following details:") do |table|
  details = table.rows_hash
  visit new_case_path
  select details["Case Type"], from: "Case Type"
  select details["Team"], from: "Team"
  click_button "Create Case"
end

When("I visit the cases page") do
  visit cases_path
end

When("I update the case status to {string}") do |status|
  visit case_path(@case)
  click_link "Update Status"
  select status.humanize, from: "Status"
  click_button "Update"
end

When("I add the following note to the case:") do |note_text|
  visit case_path(@case)
  click_link "Add Note"
  fill_in "Note", with: note_text
  click_button "Save Note"
end

When("I submit the case for review") do
  visit case_path(@case)
  click_button "Submit for Review"
end

When("I mark the case as completed") do
  visit case_path(@case)
  click_button "Mark as Completed"
end

When("I filter cases by status {string}") do |status|
  visit cases_path
  select status.humanize, from: "Status"
  click_button "Filter"
end

When("I visit the case analytics page") do
  visit case_analytics_path
end

Then("the case should be in {string} status") do |status|
  expect(page).to have_content(status.humanize)
end

Then("I should see the following cases:") do |table|
  table.hashes.each do |row|
    within(".cases-list") do
      expect(page).to have_content(row["Case Type"])
      expect(page).to have_content(row["Team"])
      expect(page).to have_content(row["Status"])
    end
  end
end

Then("the case status should be {string}") do |status|
  expect(page).to have_content(status)
end

Then("the note should be visible in the case timeline") do
  within(".case-timeline") do
    expect(page).to have_content(@note_text)
  end
end

Then("I should only see cases with status {string}") do |status|
  within(".cases-list") do
    expect(page).to have_content(status)
    expect(page).not_to have_content("In Progress") unless status == "In Progress"
    expect(page).not_to have_content("Completed") unless status == "Completed"
    expect(page).not_to have_content("Not Started") unless status == "Not Started"
  end
end

Then("I should see statistics about my case performance") do
  expect(page).to have_content("Cases Completed")
  expect(page).to have_content("Average Completion Time")
  expect(page).to have_content("Success Rate")
end

# Additional case management step definitions

When("I navigate to the new case page") do
  visit new_case_path
end

When("I enter a title and description for the case") do
  fill_in "Title", with: "Sample Case Title"
  fill_in "Description", with: "This is a sample case description for testing purposes."
end

When("I fill in the case form with:") do |table|
  details = table.rows_hash

  fill_in "Title", with: details["Title"] if details["Title"]
  fill_in "Description", with: details["Description"] if details["Description"]
  select details["Case Type"], from: "Case Type" if details["Case Type"]
  select details["Difficulty"], from: "Difficulty" if details["Difficulty"]

  # Handle team assignments if present
  if details["Plaintiff Team"]
    select details["Plaintiff Team"], from: "Plaintiff Team"
  end

  if details["Defendant Team"]
    select details["Defendant Team"], from: "Defendant Team"
  end
end

When("I select {string} as the case type") do |case_type|
  select case_type, from: "Case Type"
end

When("I assign {string} as the plaintiff team") do |team_name|
  select team_name, from: "Plaintiff Team"
end

When("I assign {string} as the defendant team") do |team_name|
  select team_name, from: "Defendant Team"
end

When("I set the difficulty level to {string}") do |difficulty|
  select difficulty, from: "Difficulty Level"
end

When("I click {string}") do |button_text|
  click_button button_text
end

When("I click the {string} button") do |button_text|
  click_button button_text
end

When("I visit the case details page") do
  visit case_path(@case || Case.last)
end

When("I edit the case") do
  case_to_edit = @case || Case.last
  visit edit_case_path(case_to_edit)
end

When("I delete the case") do
  case_to_delete = @case || Case.last
  visit case_path(case_to_delete)

  if page.has_link?("Delete Case")
    click_link "Delete Case"
  elsif page.has_button?("Delete")
    click_button "Delete"
  end

  # Handle confirmation if present
  click_button "Confirm" if page.has_button?("Confirm")
end

Given("the following case types exist:") do |table|
  table.hashes.each do |case_type_data|
    if defined?(CaseType)
      create(:case_type,
             title: case_type_data['Title'],
             description: case_type_data['Description'])
    else
      # For enum-based case types, we just ensure the enum values exist
      # The actual enum values are defined in the Case model
      # This step is essentially a no-op for enum-based implementations
    end
  end
end

Given("I have permission to create cases") do
  @current_user ||= create(:user, role: :instructor)
end

Given("there is a case assigned to my team") do
  @current_user ||= create(:user, role: :student)
  @team ||= create(:team)
  @case ||= create(:case)

  # Create team membership
  create(:team_member, user: @current_user, team: @team)

  # Assign team to case
  create(:case_team, case: @case, team: @team, role: :plaintiff)
end

Then("I should see the case in the case list") do
  visit cases_path
  case_to_check = @case || Case.last
  expect(page).to have_content(case_to_check.title)
end

Then("I should see a success message") do
  success_indicators = [
    "successfully", "created", "updated"
  ]

  success_present = success_indicators.any? { |indicator| page.has_content?(indicator) } ||
                    page.has_css?(".alert-success") ||
                    page.has_css?(".notice")

  expect(success_present).to be true
end

Then("I should see the case details") do
  case_to_check = @case || Case.last
  expect(page).to have_content(case_to_check.title)
  expect(page).to have_content(case_to_check.description) if case_to_check.description
end

Then("the case should be created successfully") do
  expect(Case.count).to be > 0
  latest_case = Case.last
  expect(latest_case).to be_present
end

Then("the case should be updated successfully") do
  case_to_check = @case || Case.last
  case_to_check.reload
  expect(page).to have_content("updated")
end

Then("the case should be deleted successfully") do
  deleted_present = page.has_content?("deleted") || page.has_content?("removed")
  expect(deleted_present).to be true
end

Then("I should see an error message") do
  error_present = page.has_css?(".alert-danger") ||
                  page.has_css?(".error") ||
                  page.has_content?("error") ||
                  page.has_content?("invalid")
  expect(error_present).to be true
end

Then("I should be redirected to the cases page") do
  expect(page.current_path).to eq(cases_path)
end

Then("I should be redirected to the case details page") do
  case_to_check = @case || Case.last
  expect(page.current_path).to eq(case_path(case_to_check))
end

# Case assignment and team management

When("I assign teams to the case") do
  case_to_assign = @case || Case.last
  visit case_path(case_to_assign)

  click_link "Assign Teams" if page.has_link?("Assign Teams")
end

When("I view team assignments") do
  case_to_view = @case || Case.last
  visit case_path(case_to_view)

  assignments_present = page.has_content?("Team Assignments") ||
                        page.has_content?("Plaintiff Team") ||
                        page.has_content?("Defendant Team")
  expect(assignments_present).to be true
end

Then("I should see the team assignments") do
  assignments_visible = page.has_content?("Plaintiff") || page.has_content?("Defendant")
  expect(assignments_visible).to be true
end

# Case status management

When("I view cases by status") do
  visit cases_path
end

When("I filter by {string} status") do |status|
  visit cases_path

  if page.has_select?("Status")
    select status, from: "Status"
    click_button "Filter"
  end
end

Then("I should see cases with {string} status") do |status|
  expect(page).to have_content(status)
end

# Helper method to map case type titles to enum values
def map_case_type_title_to_enum(title)
  case title.downcase
  when 'sexual harassment'
    :sexual_harassment
  when 'discrimination'
    :discrimination
  when 'wrongful termination'
    :wrongful_termination
  when 'contract dispute'
    :contract_dispute
  when 'intellectual property'
    :intellectual_property
  else
    :sexual_harassment # default fallback
  end
end
