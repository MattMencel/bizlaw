Feature: Invitation Management
  As an admin or organization admin
  I want to invite users to join the application by email or shareable link
  So that I can onboard new users with appropriate roles

  Background:
    Given an organization "Harvard University" with domain "harvard.edu" exists
    And a user "admin@example.com" with role "admin" exists
    And a user "orgadmin@harvard.edu" with role "instructor" exists in the organization
    And "orgadmin@harvard.edu" is an orgAdmin for "Harvard University"

  Scenario: Admin can invite users to any role via email
    Given I am signed in as "admin@example.com"
    When I invite "newuser@example.com" to join with role "instructor"
    Then an invitation should be sent to "newuser@example.com" with role "instructor"
    And I should see "Invitation sent successfully"

  Scenario: Admin can invite users to admin role
    Given I am signed in as "admin@example.com"
    When I invite "newadmin@example.com" to join with role "admin"
    Then an invitation should be sent to "newadmin@example.com" with role "admin"
    And I should see "Invitation sent successfully"

  Scenario: OrgAdmin can invite users to student role within their organization
    Given I am signed in as "orgadmin@harvard.edu"
    When I invite "student@harvard.edu" to join "Harvard University" with role "student"
    Then an invitation should be sent to "student@harvard.edu" with role "student" for "Harvard University"
    And I should see "Invitation sent successfully"

  Scenario: OrgAdmin can invite users to instructor role within their organization
    Given I am signed in as "orgadmin@harvard.edu"
    When I invite "teacher@harvard.edu" to join "Harvard University" with role "instructor"
    Then an invitation should be sent to "teacher@harvard.edu" with role "instructor" for "Harvard University"
    And I should see "Invitation sent successfully"

  Scenario: OrgAdmin can invite users to orgAdmin role within their organization
    Given I am signed in as "orgadmin@harvard.edu"
    When I invite "neworgadmin@harvard.edu" to join "Harvard University" with role "orgAdmin"
    Then an invitation should be sent to "neworgadmin@harvard.edu" with role "instructor" and orgAdmin status for "Harvard University"
    And I should see "Invitation sent successfully"

  Scenario: OrgAdmin cannot invite users to admin role
    Given I am signed in as "orgadmin@harvard.edu"
    When I try to invite "newuser@harvard.edu" to join "Harvard University" with role "admin"
    Then I should see "You are not authorized to perform this action"
    And no invitation should be sent

  Scenario: Student cannot send invitations
    Given a user "student@harvard.edu" with role "student" exists in the organization
    And I am signed in as "student@harvard.edu"
    When I try to invite "friend@harvard.edu" to join "Harvard University" with role "student"
    Then I should see "You are not authorized to perform this action"
    And no invitation should be sent

  Scenario: Instructor without orgAdmin status cannot send invitations
    Given a user "teacher@harvard.edu" with role "instructor" exists in the organization
    And I am signed in as "teacher@harvard.edu"
    When I try to invite "newstudent@harvard.edu" to join "Harvard University" with role "student"
    Then I should see "You are not authorized to perform this action"
    And no invitation should be sent

  Scenario: User accepts invitation via email link
    Given an invitation exists for "newuser@harvard.edu" with role "student" for "Harvard University"
    When "newuser@harvard.edu" clicks the invitation link
    Then they should be redirected to the registration page
    And the invitation should be marked as pending acceptance
    When they complete registration with password "password123"
    Then a new user account should be created for "newuser@harvard.edu" with role "student"
    And they should be assigned to "Harvard University"
    And the invitation should be marked as accepted
    And they should be redirected to the dashboard

  Scenario: User accepts invitation when already registered
    Given a user "existinguser@harvard.edu" with role "student" exists
    And an invitation exists for "existinguser@harvard.edu" with role "instructor" for "Harvard University"
    When "existinguser@harvard.edu" clicks the invitation link and signs in
    Then their role should be updated to "instructor"
    And they should be assigned to "Harvard University"
    And the invitation should be marked as accepted
    And they should see "Your account has been updated with new permissions"

  Scenario: Admin creates shareable invitation link
    Given I am signed in as "admin@example.com"
    When I create a shareable invitation link for role "student"
    Then a shareable invitation link should be generated
    And I should see the shareable link
    And I should see social sharing options for "Facebook", "Slack", and "X"

  Scenario: OrgAdmin creates shareable invitation link for their organization
    Given I am signed in as "orgadmin@harvard.edu"
    When I create a shareable invitation link for "Harvard University" with role "student"
    Then a shareable invitation link should be generated for "Harvard University"
    And I should see the shareable link
    And I should see social sharing options for "Facebook", "Slack", and "X"

  Scenario: User joins via shareable link
    Given a shareable invitation link exists for "Harvard University" with role "student"
    When a new user "shareuser@harvard.edu" clicks the shareable link
    Then they should be redirected to the registration page
    When they complete registration with email "shareuser@harvard.edu" and password "password123"
    Then a new user account should be created for "shareuser@harvard.edu" with role "student"
    And they should be assigned to "Harvard University"
    And they should be redirected to the dashboard

  Scenario: Invitation expires after set time period
    Given an invitation was sent to "expireduser@harvard.edu" 8 days ago
    When "expireduser@harvard.edu" clicks the invitation link
    Then they should see "This invitation has expired"
    And they should be redirected to the contact page

  Scenario: Admin can view all pending invitations
    Given I am signed in as "admin@example.com"
    And invitations exist for:
      | email                 | role       | organization      | status  |
      | pending1@example.com  | student    | Harvard University| pending |
      | pending2@example.com  | instructor | Harvard University| pending |
      | accepted@example.com  | student    | Harvard University| accepted|
    When I view the invitations list
    Then I should see 2 pending invitations
    And I should see invitation for "pending1@example.com" with role "student"
    And I should see invitation for "pending2@example.com" with role "instructor"
    And I should not see the accepted invitation

  Scenario: OrgAdmin can view pending invitations for their organization only
    Given I am signed in as "orgadmin@harvard.edu"
    And another organization "MIT" with domain "mit.edu" exists
    And invitations exist for:
      | email                | role    | organization      | status  |
      | harvard1@harvard.edu | student | Harvard University| pending |
      | mit1@mit.edu         | student | MIT               | pending |
    When I view the invitations list
    Then I should see 1 pending invitation
    And I should see invitation for "harvard1@harvard.edu"
    And I should not see invitation for "mit1@mit.edu"

  Scenario: Admin can resend invitation
    Given I am signed in as "admin@example.com"
    And an invitation exists for "pending@example.com" with role "student"
    When I resend the invitation to "pending@example.com"
    Then a new invitation email should be sent to "pending@example.com"
    And I should see "Invitation resent successfully"

  Scenario: Admin can revoke invitation
    Given I am signed in as "admin@example.com"
    And an invitation exists for "revoke@example.com" with role "student"
    When I revoke the invitation for "revoke@example.com"
    Then the invitation should be marked as revoked
    And I should see "Invitation revoked successfully"
    When "revoke@example.com" tries to use the invitation link
    Then they should see "This invitation is no longer valid"

  Scenario: Prevent duplicate invitations to same email
    Given I am signed in as "admin@example.com"
    And an invitation exists for "duplicate@example.com" with role "student"
    When I try to invite "duplicate@example.com" again with role "instructor"
    Then I should see "An invitation has already been sent to this email address"
    And no new invitation should be created

  Scenario: OrgAdmin cannot invite users to other organizations
    Given I am signed in as "orgadmin@harvard.edu"
    And another organization "MIT" with domain "mit.edu" exists
    When I try to invite "user@mit.edu" to join "MIT" with role "student"
    Then I should see "You are not authorized to perform this action"
    And no invitation should be sent
