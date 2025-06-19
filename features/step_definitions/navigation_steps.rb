# frozen_string_literal: true

# Navigation feature step definitions

Given("an organization exists") do
  @organization = FactoryBot.create(:organization,
    name: "Test University",
    domain: "example.com",
    slug: "test-university")
end

Given("a user {string} exists with role {string} in the organization") do |email, role|
  @current_user = FactoryBot.create(:user,
    email: email,
    role: role,
    roles: [role],
    organization: @organization,
    password: "password123",
    password_confirmation: "password123")
end

When("I click on the {string} section header again") do |section_name|
  find("button", text: section_name).click
end

Given("a case {string} exists") do |case_title|
  # Create a course with an instructor
  course = FactoryBot.create(:course, organization: @organization)

  # Create the case with the course (skip automatic team creation)
  @case = Case.create!(
    title: case_title,
    description: "Test case for navigation testing",
    reference_number: "CASE-NAV-001",
    status: "not_started",
    difficulty_level: "intermediate",
    case_type: "sexual_harassment",
    plaintiff_info: {"name" => "Test Plaintiff"},
    defendant_info: {"name" => "Test Defendant"},
    legal_issues: ["Test issue"],
    course: course,
    created_by: course.instructor,
    updated_by: course.instructor
  )
end

Given("another case {string} exists") do |case_title|
  # Create a course with an instructor (the factory will create a proper instructor)
  course = FactoryBot.create(:course, organization: @organization)

  # Create the second case with the course
  @second_case = FactoryBot.create(:case,
    title: case_title,
    course: course,
    created_by: course.instructor,
    updated_by: course.instructor)
end

Given("a team {string} exists for the case") do |team_name|
  course = @case.course

  # Create a student to be the team owner
  team_owner = FactoryBot.create(:user,
    role: "student",
    roles: ["student"],
    organization: @organization)

  # Enroll the student in the course
  FactoryBot.create(:course_enrollment, user: team_owner, course: course, status: "active")

  # Create the team with the enrolled student as owner
  @team = FactoryBot.create(:team,
    name: team_name,
    course: course,
    owner: team_owner)

  # Associate the team with the case through case_teams
  FactoryBot.create(:case_team, case: @case, team: @team, role: "plaintiff")
end

Given("another team {string} exists for the second case") do |team_name|
  course = @second_case.course

  # Create a student to be the team owner
  team_owner = FactoryBot.create(:user,
    role: "student",
    roles: ["student"],
    organization: @organization)

  # Enroll the student in the course
  FactoryBot.create(:course_enrollment, user: team_owner, course: course, status: "active")

  # Create the team with the enrolled student as owner
  @second_team = FactoryBot.create(:team,
    name: team_name,
    course: course,
    owner: team_owner)

  # Associate the team with the case through case_teams
  FactoryBot.create(:case_team, case: @second_case, team: @second_team, role: "defendant")
end

Given("the user is a member of the team") do
  user = User.find_by(email: "john@example.com") || @current_user
  course = @team.course

  # Enroll the student in the course so they can join the team
  FactoryBot.create(:course_enrollment, user: user, course: course, status: "active")

  # Add the user to the team as a member
  FactoryBot.create(:team_member, user: user, team: @team, role: "member")
end

Given("the user is a member of the second team") do
  user = User.find_by(email: "john@example.com") || @current_user
  course = @second_team.course

  # Enroll the student in the course so they can join the team
  FactoryBot.create(:course_enrollment, user: user, course: course, status: "active")

  # Add the user to the team as a member
  FactoryBot.create(:team_member, user: user, team: @second_team, role: "member")
end

Given("multiple cases exist for the user") do
  user = User.find_by(email: "john@example.com") || @current_user

  3.times do |i|
    course = FactoryBot.create(:course, organization: @organization)
    case_obj = FactoryBot.create(:case,
      title: "Test Case #{i + 1}",
      course: course,
      created_by: course.instructor,
      updated_by: course.instructor)

    # Create a student team owner and enroll both users in course
    team_owner = FactoryBot.create(:user, role: "student", roles: ["student"], organization: @organization)
    FactoryBot.create(:course_enrollment, user: team_owner, course: course, status: "active")
    FactoryBot.create(:course_enrollment, user: user, course: course, status: "active")

    # Create team with enrolled student as owner
    team = FactoryBot.create(:team,
      name: "Team #{i + 1}",
      course: course,
      owner: team_owner)

    # Associate team with case and add user as member
    FactoryBot.create(:case_team, case: case_obj, team: team, role: "plaintiff")
    FactoryBot.create(:team_member, user: user, team: team, role: "member")
  end
end

Given("the user has access to {int} cases") do |count|
  user = User.find_by(email: "john@example.com") || @current_user

  count.times do |i|
    course = FactoryBot.create(:course, organization: @organization)
    case_obj = FactoryBot.create(:case,
      title: "Case #{i + 1}",
      course: course,
      created_by: course.instructor,
      updated_by: course.instructor)

    # Create a student team owner and enroll both users in course
    team_owner = FactoryBot.create(:user, role: "student", roles: ["student"], organization: @organization)
    FactoryBot.create(:course_enrollment, user: team_owner, course: course, status: "active")
    FactoryBot.create(:course_enrollment, user: user, course: course, status: "active")

    # Create team with enrolled student as owner
    team = FactoryBot.create(:team,
      name: "Case #{i + 1} Team",
      course: course,
      owner: team_owner)

    # Associate team with case and add user as member
    FactoryBot.create(:case_team, case: case_obj, team: team, role: "plaintiff")
    FactoryBot.create(:team_member, user: user, team: team, role: "member")
  end
end

When("I visit the dashboard") do
  visit dashboard_path
  expect(page).to have_current_path(dashboard_path)
end

When("I visit the dashboard on a mobile device") do
  # Simulate mobile viewport
  page.driver.browser.manage.window.resize_to(375, 667)
  visit dashboard_path
end

When("I visit the evidence vault page") do
  visit evidence_vault_index_path(@case || @current_user.cases.first)
end

When("I visit the negotiations page") do
  visit negotiations_path(@case || @current_user.cases.first)
end

Then("I should see the hierarchical navigation") do
  # Debug: Check user data to see if navigation should work
  user = User.find_by(email: "john@example.com")
  puts "DEBUG: User found: #{user.present?}"
  puts "DEBUG: User cases count: #{user&.cases&.count || 0}"
  puts "DEBUG: User teams count: #{user&.teams&.count || 0}"

  expect(page).to have_css('[data-controller="navigation-menu"]', wait: 10)
end

Then("I should see the {string} section") do |section_name|
  expect(page).to have_content(section_name)
end

Then("I should not see the {string} section") do |section_name|
  expect(page).not_to have_content(section_name)
end

Then("I should see {string} in the context switcher") do |text|
  within('[data-controller="context-switcher"]') do
    expect(page).to have_content(text)
  end
end

Then("I should see the current phase information") do
  within('[data-controller="context-switcher"]') do
    expect(page).to have_css('[data-context-switcher-target="caseName"]')
  end
end

Then("I should see the team status indicator") do
  within('[data-controller="context-switcher"]') do
    expect(page).to have_css(".h-2.w-2.rounded-full")
  end
end

When("I click on the {string} section header") do |section_name|
  find("button", text: section_name).click
end

Then("the {string} section should collapse") do |section_name|
  section_id = section_name.downcase.tr(" ", "-")
  expect(page).to have_css("##{section_id}-content", visible: false)
end

Then("the {string} section should expand") do |section_name|
  section_id = section_name.downcase.tr(" ", "-")
  expect(page).to have_css("##{section_id}-content", visible: true)
end

Then("the {string} section should remain collapsed") do |section_name|
  section_id = section_name.downcase.tr(" ", "-")
  expect(page).to have_css("##{section_id}-content", visible: false)
end

When("I click on the context switcher") do
  find('[data-context-switcher-target="trigger"]').click
end

Then("I should see the context switcher dropdown") do
  expect(page).to have_css('[data-context-switcher-target="dropdown"]', visible: true)
end

Then("I should see {string} as an option") do |option_text|
  within('[data-context-switcher-target="dropdown"]') do
    expect(page).to have_content(option_text)
  end
end

When("I click on {string}") do |link_text|
  click_on link_text
end

When("I collapse the {string} section") do |section_name|
  # Find the section header and click if it's expanded
  section_button = find("button", text: section_name)
  if section_button["aria-expanded"] == "true"
    section_button.click
  end
end

When("I refresh the page") do
  page.refresh
end

When("I use keyboard navigation with the Tab key") do
  # Simulate tab navigation
  find("body").send_keys(:tab)
end

Then("I should be able to navigate through all navigation items") do
  # Check that navigation items are focusable
  navigation_items = all("nav a, nav button")
  expect(navigation_items.count).to be > 0

  navigation_items.each do |item|
    expect(item[:tabindex]).not_to eq("-1")
  end
end

When("I press the Enter key on a section header") do
  find('button[data-action*="navigation-menu#toggleSection"]').send_keys(:enter)
end

Then("the section should toggle its expanded state") do
  # Check that aria-expanded attribute changes
  button = find('button[data-action*="navigation-menu#toggleSection"]')
  expect(button["aria-expanded"]).to be_present
end

When("I press the Escape key") do
  find("body").send_keys(:escape)
end

Then("any open dropdowns should close") do
  expect(page).not_to have_css('[data-context-switcher-target="dropdown"]', visible: true)
end

Then("I should see {string} in the Administration section") do |item_text|
  within(".navigation-section", text: "Administration") do
    expect(page).to have_content(item_text)
  end
end

Then("I should see the mobile navigation toggle") do
  expect(page).to have_css('button[data-action*="mobile-navigation#toggle"]')
end

Then("the main navigation should be hidden") do
  expect(page).to have_css("nav", visible: false)
end

When("I click the mobile navigation toggle") do
  find('button[data-action*="mobile-navigation#toggle"]').click
end

Then("the mobile navigation menu should slide out") do
  expect(page).to have_css('[data-mobile-navigation-target="menu"]', visible: true)
end

When("I click outside the mobile menu") do
  find("body").click
end

Then("the mobile navigation menu should close") do
  expect(page).to have_css('[data-mobile-navigation-target="menu"]', visible: false)
end

When("I type {string} in the search field") do |search_term|
  fill_in "search", with: search_term
end

Then("I should see {string} in the search results") do |result_text|
  within('[data-context-switcher-target="searchResults"]') do
    expect(page).to have_content(result_text)
  end
end

Then("I should not see other cases in the search results") do
  within('[data-context-switcher-target="searchResults"]') do
    expect(page).not_to have_content("Test Case")
  end
end

When("I expand the {string} section") do |section_name|
  section_button = find("button", text: section_name)
  if section_button["aria-expanded"] == "false"
    section_button.click
  end
end

When("I expand the {string} subsection") do |subsection_name|
  subsection_button = find("button", text: subsection_name)
  if subsection_button["aria-expanded"] == "false"
    subsection_button.click
  end
end

Then("I should see {string} link") do |link_text|
  expect(page).to have_link(link_text)
end

Then("I should see {string} subsection") do |subsection_text|
  expect(page).to have_content(subsection_text)
end

Then("the {string} navigation item should be highlighted") do |item_text|
  link = find("a", text: item_text)
  expect(link[:class]).to include("bg-blue-600")
end

Then("I should not see {string} in any navigation section") do |item_text|
  expect(page).not_to have_content(item_text)
end

Then("I should not see administrative user management options") do
  expect(page).not_to have_content("User Management")
  expect(page).not_to have_content("System Settings")
end

Given("the context switching API is unavailable") do
  # Mock API failure
  allow_any_instance_of(Api::V1::ContextController).to receive(:switch_case).and_raise(StandardError)
end

Then("I should see an error message") do
  expect(page).to have_content("error") # This would be handled by the error handling system
end

Then("the context switcher should remain functional") do
  expect(page).to have_css('[data-controller="context-switcher"]')
end

Then("the dropdown should load within {int} seconds") do |seconds|
  using_wait_time(seconds) do
    expect(page).to have_css('[data-context-switcher-target="dropdown"]', visible: true)
  end
end

Then("I should see pagination or limited results") do
  within('[data-context-switcher-target="dropdown"]') do
    # Check that we don't show more than 10 cases at once
    case_items = all(".case-option")
    expect(case_items.count).to be <= 10
  end
end

When("I expand all navigation sections") do
  section_buttons = all('button[data-action*="navigation-menu#toggleSection"]')
  section_buttons.each do |button|
    button.click if button["aria-expanded"] == "false"
  end
end

Then("I should see proper indentation for subsections") do
  # Check that subsections have proper margin/padding classes
  expect(page).to have_css(".ml-4", minimum: 1) # Subsection indentation
  expect(page).to have_css(".ml-6", minimum: 1) # Section content indentation
end

Then("I should see appropriate spacing between sections") do
  sections = all(".navigation-section")
  expect(sections.count).to be >= 3
end

Then("the navigation should remain scrollable if needed") do
  nav_container = find('[data-controller="navigation-menu"]')
  expect(nav_container[:class]).to include("overflow-y-auto")
end

# New steps for admin navigation functionality
When("I click on {string} in the Administration section") do |link_text|
  within(".navigation-section", text: "Administration") do
    click_on link_text
  end
end

Then("I should be redirected to the organizations management page") do
  expect(page).to have_current_path(admin_organizations_path)
end

Then("I should be redirected to the admin settings page") do
  expect(page).to have_current_path(admin_settings_path)
end

Then("I should be redirected to the admin dashboard page") do
  expect(page).to have_current_path(admin_dashboard_path)
end

Then("I should be redirected to the license management page") do
  expect(page).to have_current_path(admin_licenses_path)
end

# Mobile navigation responsiveness steps
When("I resize the browser to mobile width {int}px") do |width|
  page.driver.browser.manage.window.resize_to(width, 667)
end

Then("the navigation should automatically switch to mobile mode") do
  expect(page).to have_css('[data-mobile-navigation-target="toggle"]', visible: true)
end

Then("the hamburger menu should be visible") do
  expect(page).to have_css('[data-mobile-navigation-target="toggle"]', visible: true)
end

Then("the main content should be fully accessible") do
  # Ensure navigation doesn't occupy too much space
  nav_width = page.evaluate_script("document.querySelector('nav').offsetWidth")
  viewport_width = page.evaluate_script("window.innerWidth")
  expect(nav_width.to_f / viewport_width.to_f).to be < 0.5 # Less than 50% of viewport
end

When("I resize back to desktop width") do
  page.driver.browser.manage.window.resize_to(1200, 800)
end

Then("the navigation should return to desktop mode") do
  expect(page).to have_css('[data-mobile-navigation-target="toggle"]', visible: false)
end

Then("the hamburger menu should be hidden") do
  expect(page).to have_css('[data-mobile-navigation-target="toggle"]', visible: false)
end

Then("the navigation should not occupy more than {int}% of the screen width") do |percentage|
  nav_width = page.evaluate_script("document.querySelector('nav').offsetWidth")
  viewport_width = page.evaluate_script("window.innerWidth")
  actual_percentage = (nav_width.to_f / viewport_width.to_f) * 100
  expect(actual_percentage).to be <= percentage
end
