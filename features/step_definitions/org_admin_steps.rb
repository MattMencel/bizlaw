# frozen_string_literal: true

Given('an organization {string} with domain {string} exists') do |org_name, domain|
  Organization.create!(
    name: org_name,
    domain: domain,
    slug: Organization.generate_slug_from_name(org_name)
  )
end

Given('a user {string} with role {string} exists in the organization') do |email, role|
  org_domain = email.split('@').last
  organization = Organization.find_by!(domain: org_domain)
  User.create!(
    email: email,
    first_name: email.split('@').first.split('.').first.capitalize,
    last_name: email.split('@').first.split('.').last&.capitalize || 'User',
    role: role,
    organization: organization,
    password: 'password123',
    password_confirmation: 'password123'
  )
end

Given('a user {string} with role {string} exists in {string}') do |email, role, org_name|
  organization = Organization.find_by!(name: org_name)
  User.create!(
    email: email,
    first_name: email.split('@').first.split('.').first.capitalize,
    last_name: email.split('@').first.split('.').last&.capitalize || 'User',
    role: role,
    organization: organization,
    password: 'password123',
    password_confirmation: 'password123'
  )
end

Given('a user {string} is an orgAdmin for {string}') do |email, org_name|
  user = User.find_by!(email: email)
  organization = Organization.find_by!(name: org_name)
  user.update!(organization: organization, org_admin: true)
end

Given('no orgAdmin exists for {string}') do |org_name|
  organization = Organization.find_by!(name: org_name)
  organization.users.update_all(org_admin: false)
end

Given('{string} is an orgAdmin for {string}') do |email, org_name|
  user = User.find_by!(email: email)
  organization = Organization.find_by!(name: org_name)
  user.update!(organization: organization, org_admin: true)
end

Given('{string} is an orgAdmin and instructor for {string}') do |email, org_name|
  user = User.find_by!(email: email)
  organization = Organization.find_by!(name: org_name)
  user.update!(organization: organization, role: :instructor, org_admin: true)
end

Given('{string} is an instructor but not an orgAdmin for {string}') do |email, org_name|
  user = User.find_by!(email: email)
  organization = Organization.find_by!(name: org_name)
  user.update!(organization: organization, role: :instructor, org_admin: false)
end

Given('a term {string} exists for {string}') do |term_name, org_name|
  organization = Organization.find_by!(name: org_name)
  Term.create!(
    name: term_name,
    organization: organization,
    start_date: Date.current,
    end_date: 1.year.from_now
  )
end

Given('a course {string} exists for {string}') do |course_name, org_name|
  organization = Organization.find_by!(name: org_name)
  term = organization.terms.first || Term.create!(
    name: "Default Term",
    organization: organization,
    start_date: Date.current,
    end_date: 1.year.from_now
  )
  Course.create!(
    name: course_name,
    organization: organization,
    term: term
  )
end

Given('another organization {string} with domain {string} exists') do |org_name, domain|
  Organization.create!(
    name: org_name,
    domain: domain,
    slug: Organization.generate_slug_from_name(org_name)
  )
end

When('the first instructor {string} is created for the organization') do |email|
  # This step assumes the user creation triggers the callback
  user = User.find_by!(email: email)
  user.assign_first_instructor_as_org_admin
end

When('I assign {string} as orgAdmin for {string}') do |email, org_name|
  user = User.find_by!(email: email)
  visit admin_user_path(user)
  click_button "Assign Org Admin"
end

When('I create a new term {string} with start date {string} and end date {string} for {string}') do |term_name, start_date, end_date, org_name|
  organization = Organization.find_by!(name: org_name)
  visit "/admin/organizations/#{organization.id}/terms/new"
  fill_in "Name", with: term_name
  fill_in "Start date", with: start_date
  fill_in "End date", with: end_date
  click_button "Create Term"
end

When('I create a new course {string} for term {string} in {string}') do |course_name, term_name, org_name|
  organization = Organization.find_by!(name: org_name)
  term = organization.terms.find_by!(name: term_name)
  visit "/admin/organizations/#{organization.id}/courses/new"
  fill_in "Name", with: course_name
  select term_name, from: "Term"
  click_button "Create Course"
end

When('I assign instructor {string} to course {string} in {string}') do |email, course_name, org_name|
  organization = Organization.find_by!(name: org_name)
  course = organization.courses.find_by!(name: course_name)
  user = User.find_by!(email: email)
  visit "/admin/organizations/#{organization.id}/courses/#{course.id}/edit"
  select user.full_name, from: "Instructor"
  click_button "Update Course"
end

When('I assign myself as instructor to course {string}') do |course_name|
  current_user = User.find_by!(email: @current_user_email)
  course = current_user.organization.courses.find_by!(name: course_name)
  visit "/admin/organizations/#{current_user.organization.id}/courses/#{course.id}/edit"
  select current_user.full_name, from: "Instructor"
  click_button "Update Course"
end

When('I try to manage course {string} from {string}') do |course_name, org_name|
  organization = Organization.find_by!(name: org_name)
  course = organization.courses.find_by!(name: course_name)
  visit "/admin/organizations/#{organization.id}/courses/#{course.id}/edit"
end

When('I try to assign instructor {string} to course {string}') do |email, course_name|
  current_user = User.find_by!(email: @current_user_email)
  course = current_user.organization.courses.find_by!(name: course_name)
  user = User.find_by!(email: email)
  visit "/admin/organizations/#{current_user.organization.id}/courses/#{course.id}/edit"
  select user.full_name, from: "Instructor"
  click_button "Update Course"
end

When('I update the {string} organization name to {string}') do |old_name, new_name|
  organization = Organization.find_by!(name: old_name)
  visit "/admin/organizations/#{organization.id}/edit"
  fill_in "Name", with: new_name
  click_button "Update Organization"
end

When('I try to assign {string} as orgAdmin for {string}') do |email, org_name|
  user = User.find_by!(email: email)
  visit admin_user_path(user)
  click_button "Assign Org Admin"
end

When('I try to access the organization admin panel for {string}') do |org_name|
  organization = Organization.find_by!(name: org_name)
  visit "/admin/organizations/#{organization.id}"
end

When('I visit the organization admin dashboard for {string}') do |org_name|
  organization = Organization.find_by!(name: org_name)
  visit "/admin/organizations/#{organization.id}"
end

When('I try to manage {string}') do |org_name|
  organization = Organization.find_by!(name: org_name)
  visit "/admin/organizations/#{organization.id}"
end

When('I try to assign {string} as orgAdmin for {string}') do |email, org_name|
  user = User.find_by!(email: email)
  visit admin_user_path(user)
  click_button "Assign Org Admin"
end

Then('{string} should be assigned as orgAdmin for {string}') do |email, org_name|
  user = User.find_by!(email: email)
  organization = Organization.find_by!(name: org_name)
  expect(user.org_admin?).to be true
  expect(user.organization).to eq organization
end

Then('{string} should remain an instructor') do |email|
  user = User.find_by!(email: email)
  expect(user.instructor?).to be true
end

Then('{string} should be an orgAdmin for {string}') do |email, org_name|
  user = User.find_by!(email: email)
  organization = Organization.find_by!(name: org_name)
  expect(user.org_admin?).to be true
  expect(user.organization).to eq organization
end

Then('the term {string} should be created for {string}') do |term_name, org_name|
  organization = Organization.find_by!(name: org_name)
  term = organization.terms.find_by!(name: term_name)
  expect(term).to be_present
end

Then('the course {string} should be created for {string}') do |course_name, org_name|
  organization = Organization.find_by!(name: org_name)
  course = organization.courses.find_by!(name: course_name)
  expect(course).to be_present
end

Then('{string} should be assigned as instructor for {string}') do |email, course_name|
  user = User.find_by!(email: email)
  course = Course.find_by!(name: course_name)
  expect(course.instructor).to eq user
end

Then('I should be assigned as instructor for {string}') do |course_name|
  current_user = User.find_by!(email: @current_user_email)
  course = Course.find_by!(name: course_name)
  expect(course.instructor).to eq current_user
end

Then('the organization name should be {string}') do |new_name|
  organization = Organization.find_by!(name: new_name)
  expect(organization).to be_present
end

Then('{string} should not be an orgAdmin') do |email|
  user = User.find_by!(email: email)
  expect(user.org_admin?).to be false
end

Then('I should see organization statistics for {string}') do |org_name|
  organization = Organization.find_by!(name: org_name)
  expect(page).to have_content(organization.name)
  expect(page).to have_content("Users")
  expect(page).to have_content("Courses")
end
