# frozen_string_literal: true

Given("a user exists with email {string} and password {string}") do |email, password|
  @user = create(:user,
                email: email,
                password: password,
                password_confirmation: password,
                confirmed_at: Time.current)
end

Given("I am logged in") do
  @current_user ||= create(:user, :confirmed)
  login_as(@current_user, scope: :user)
end

Given("the user has requested a password reset") do
  @user.send_reset_password_instructions
  @reset_token = @user.reset_password_token
end

When("I visit the registration page") do
  visit new_user_registration_path
end

When("I visit the login page") do
  visit new_user_session_path
end

When("I visit the password reset request page") do
  visit new_user_password_path
end

When("I visit the password reset page with the reset token") do
  visit edit_user_password_path(reset_password_token: @reset_token)
end

When("I visit my account settings") do
  visit edit_user_registration_path
end

When("I fill in the registration form with:") do |table|
  form_data = table.rows_hash

  fill_in "Email", with: form_data["Email"]
  fill_in "First name", with: form_data["First name"]
  fill_in "Last name", with: form_data["Last name"]
  fill_in "Password", with: form_data["Password"]
  fill_in "Password confirmation", with: form_data["Password confirmation"]
end

When("I fill in the login form with:") do |table|
  form_data = table.rows_hash

  fill_in "Email", with: form_data["Email"]
  fill_in "Password", with: form_data["Password"]
end

When("I fill in the new password form with:") do |table|
  form_data = table.rows_hash

  fill_in "New password", with: form_data["New password"]
  fill_in "Confirm new password", with: form_data["Confirm new password"]
end

When("I update my profile with:") do |table|
  form_data = table.rows_hash

  fill_in "First name", with: form_data["First name"]
  fill_in "Last name", with: form_data["Last name"]
end

When("I click {string}") do |button|
  click_button button
end

When("I check {string}") do |checkbox|
  check checkbox
end

When("I make {int} failed login attempts") do |attempts|
  attempts.times do
    visit new_user_session_path
    fill_in "Email", with: @user.email
    fill_in "Password", with: "wrong_password"
    click_button "Log in"
  end
end

When("I am inactive for {int} minutes") do |minutes|
  Timecop.travel(minutes.minutes.from_now)
  Warden.test_reset! if defined?(Warden)
end

When("I try to access a protected page") do
  visit dashboard_path
end

When("I register with email {string}") do |email|
  visit new_user_registration_path
  fill_in "Email", with: email
  fill_in "Password", with: "SecurePass123!"
  fill_in "Password confirmation", with: "SecurePass123!"
  click_button "Sign up"
end

When("I click the confirmation link in the email") do
  open_email(@user.email)
  click_first_link_in_email
end

Then("I should be redirected to the dashboard") do
  expect(page).to have_current_path(dashboard_path)
end

Then("I should be redirected to Google for authentication") do
  expect(page).to have_current_path(dashboard_path)
end

Then("I should be redirected back and signed in successfully") do
  expect(page).to have_content("Successfully authenticated")
  expect(page).to have_current_path(dashboard_path)
end

Then("a password reset email should be sent to {string}") do |email|
  expect(ActionMailer::Base.deliveries.last.to).to include(email)
  expect(ActionMailer::Base.deliveries.last.subject).to include("Reset password instructions")
end

Then("I should be able to log in with the new password") do
  visit new_user_session_path
  fill_in "Email", with: @user.email
  fill_in "Password", with: "NewPass456!"
  click_button "Log in"
  expect(page).to have_content("Signed in successfully")
end

Then("the account should be locked") do
  expect(@user.reload.access_locked?).to be true
end

Then("an unlock email should be sent to {string}") do |email|
  expect(ActionMailer::Base.deliveries.last.to).to include(email)
  expect(ActionMailer::Base.deliveries.last.subject).to include("Unlock Instructions")
end

Then("I should remain logged in after closing and reopening the browser") do
  expire_cookies
  visit dashboard_path
  expect(page).to have_content("Welcome back")
  expect(page).not_to have_content("You need to sign in")
end

Then("my profile should display the updated information") do
  visit account_path
  expect(page).to have_content("Jane")
  expect(page).to have_content("Smith")
end

Then("I should receive a confirmation email") do
  expect(ActionMailer::Base.deliveries.last.subject).to include("Confirmation instructions")
end

Then("I should be able to log in") do
  visit new_user_session_path
  fill_in "Email", with: "new@example.com"
  fill_in "Password", with: "SecurePass123!"
  click_button "Log in"
  expect(page).to have_content("Signed in successfully")
end

Given("I am a registered user") do
  @current_user = create_user
end

Given("I am signed in") do
  @current_user ||= create(:user)
  sign_in_user(@current_user)
end

Given("I am signed out") do
  sign_out_user
end

Given("I am signed in as {string}") do |email|
  @current_user = User.find_by(email: email) || create(:user, email: email)
  sign_in_user(@current_user)
end

When("I sign in with Google") do
  mock_google_oauth
  visit new_user_session_path
  click_link "Sign in with Google"
end

When("I sign in with Google as {string}") do |email|
  mock_google_oauth(email: email)
  visit new_user_session_path
  click_link "Sign in with Google"
end

When("Google authentication fails") do
  # Failure is set in the Before hook for @oauth_failure scenarios
end

When("I sign out") do
  click_link "Sign out"
end

Then("I should be redirected to the login page") do
  expect(page).to have_current_path(new_user_session_path)
end

Then("I should remain logged in after closing and reopening the browser") do
  expire_cookies
  visit dashboard_path
  expect(page).to have_content("Welcome back")
  expect(page).not_to have_content("You need to sign in")
end

Then("my profile should display the updated information") do
  visit account_path
  expect(page).to have_content("Jane")
  expect(page).to have_content("Smith")
end

Then("I should be signed in") do
  expect(page).to have_content("Sign out")
  expect(page).not_to have_content("Sign in")
end

Then("I should be signed out") do
  expect(page).not_to have_content("Sign out")
  expect(page).to have_content("Sign in")
end

Then("I should see an authentication error message") do
  expect(page).to have_content("Authentication failed. Please try again.")
end

Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end

Then("I should see a message {string}") do |message|
  expect(page).to have_content(message)
end

Then("I should see a success message {string}") do |message|
  expect(page).to have_content(message)
end

# Additional authentication steps for missing scenarios

Given("I am logged in as an admin or instructor") do
  role = %i[admin instructor].sample
  @current_user = create(:user, role: role, confirmed_at: Time.current)
  sign_in_user(@current_user)
end

Given("I am logged in as an admin") do
  @current_user = create(:user, role: :admin, confirmed_at: Time.current)
  sign_in_user(@current_user)
end

Given("I am logged in as an instructor") do
  @current_user = create(:user, role: :instructor, confirmed_at: Time.current)
  sign_in_user(@current_user)
end

Given("I am logged in as a student") do
  @current_user = create(:user, role: :student, confirmed_at: Time.current)
  sign_in_user(@current_user)
end

Given("I assign the role {string} to {string}") do |role, email|
  user = User.find_by(email: email) || create(:user, email: email)
  user.update!(role: role.downcase)
end

Then("I should see my role displayed as {string} on the dashboard") do |role|
  visit dashboard_path
  expect(page).to have_content(role)
end

Then("I should see a warning message {string}") do |message|
  expect(page).to have_content(message)
end

Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end

When("I navigate to the sign out page") do
  visit destroy_user_session_path
end

When("I click the Google sign in button") do
  mock_google_oauth
  click_link "Sign in with Google"
end
