Feature: User Authentication
  As a user
  I want to authenticate with my Google account
  So that I can securely access the application

  Scenario: Successful Google OAuth authentication
    When I visit the login page
    And I click "Sign in with Google"
    Then I should be redirected to Google for authentication
    And I should be redirected back and signed in successfully
    And I should be redirected to the dashboard

  @oauth_failure
  Scenario: Failed Google OAuth authentication
    When I visit the login page
    And I click "Sign in with Google"
    And Google authentication fails
    Then I should see an authentication error message
    And I should be signed out

  Scenario: Session timeout
    Given I am signed in
    When I am inactive for 30 minutes
    And I try to access a protected page
    Then I should be redirected to the login page
    And I should see a message "You need to sign in or sign up before continuing."

  Scenario: Account settings update
    Given I am signed in
    When I visit my account settings
    And I update my profile with:
      | field      | value          |
      | First name| Jane           |
      | Last name | Smith          |
    And I click "Update profile"
    Then I should see a success message "Profile updated successfully"
    And my profile should display the updated information

  Scenario: Sign out
    Given I am signed in
    When I sign out
    Then I should be signed out
    And I should be redirected to the login page

  Scenario: User sees assigned role after login
    Given I am a user with the role "Instructor"
    When I sign in with Google
    Then I should see my role displayed as "Instructor" on the dashboard

  Scenario: Admin assigns instructor role to a user
    Given I am signed in as an admin
    And there is a user with the email "instructor@example.com"
    When I assign the role "Instructor" to "instructor@example.com"
    Then that user should have the role "Instructor"
    And they should see their role as "Instructor" after logging in

  @future
  Scenario: Multiple OAuth providers
    When I visit the login page
    Then I should see "Sign in with Google"
    # Future providers will be added here
    # And I should see "Sign in with GitHub"
    # And I should see "Sign in with Microsoft"
