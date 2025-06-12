Feature: Organization Admin Management
  As an organization admin (orgAdmin)
  I want to manage my organization, terms, courses, and assign other users as orgAdmins
  So that I can effectively administer my educational institution

  Background:
    Given an organization "Harvard University" with domain "harvard.edu" exists
    And a user "john@harvard.edu" with role "instructor" exists in the organization
    And a user "jane@harvard.edu" with role "instructor" exists in the organization
    And a user "student@harvard.edu" with role "student" exists in the organization

  Scenario: First instructor becomes orgAdmin automatically for their organization
    Given no orgAdmin exists for "Harvard University"
    When the first instructor "john@harvard.edu" is created for the organization
    Then "john@harvard.edu" should be assigned as orgAdmin for "Harvard University"
    And "john@harvard.edu" should remain an instructor

  Scenario: orgAdmin can assign another user as orgAdmin within their organization
    Given "john@harvard.edu" is an orgAdmin for "Harvard University"
    And I am signed in as "john@harvard.edu"
    When I assign "jane@harvard.edu" as orgAdmin for "Harvard University"
    Then "jane@harvard.edu" should be an orgAdmin for "Harvard University"
    And "jane@harvard.edu" should remain an instructor
    And I should see a success message "User successfully assigned as organization admin"

  Scenario: orgAdmin can manage terms within their organization
    Given "john@harvard.edu" is an orgAdmin for "Harvard University"
    And I am signed in as "john@harvard.edu"
    When I create a new term "Fall 2025" with start date "2025-08-15" and end date "2025-12-15" for "Harvard University"
    Then the term "Fall 2025" should be created for "Harvard University"
    And I should see "Term created successfully"

  Scenario: orgAdmin can manage courses within their organization
    Given "john@harvard.edu" is an orgAdmin for "Harvard University"
    And I am signed in as "john@harvard.edu"
    And a term "Fall 2025" exists for "Harvard University"
    When I create a new course "Business Law 101" for term "Fall 2025" in "Harvard University"
    Then the course "Business Law 101" should be created for "Harvard University"
    And I should see "Course created successfully"

  Scenario: orgAdmin can assign instructors to courses within their organization
    Given "john@harvard.edu" is an orgAdmin for "Harvard University"
    And I am signed in as "john@harvard.edu"
    And a course "Business Law 101" exists for "Harvard University"
    When I assign instructor "jane@harvard.edu" to course "Business Law 101" in "Harvard University"
    Then "jane@harvard.edu" should be assigned as instructor for "Business Law 101"
    And I should see "Instructor assigned successfully"

  Scenario: orgAdmin who is also an instructor can teach courses
    Given "john@harvard.edu" is an orgAdmin and instructor for "Harvard University"
    And I am signed in as "john@harvard.edu"
    And a course "Business Law 101" exists for "Harvard University"
    When I assign myself as instructor to course "Business Law 101"
    Then I should be assigned as instructor for "Business Law 101"
    And I should see "Instructor assigned successfully"

  Scenario: orgAdmin cannot manage courses in other organizations
    Given "john@harvard.edu" is an orgAdmin for "Harvard University"
    And another organization "MIT" with domain "mit.edu" exists
    And a course "Contract Law" exists for "MIT"
    And I am signed in as "john@harvard.edu"
    When I try to manage course "Contract Law" from "MIT"
    Then I should see "You are not authorized to perform this action"

  Scenario: orgAdmin cannot assign instructors from other organizations
    Given "john@harvard.edu" is an orgAdmin for "Harvard University"
    And another organization "MIT" with domain "mit.edu" exists
    And a user "prof@mit.edu" with role "instructor" exists in "MIT"
    And a course "Business Law 101" exists for "Harvard University"
    And I am signed in as "john@harvard.edu"
    When I try to assign instructor "prof@mit.edu" to course "Business Law 101"
    Then I should see "You are not authorized to perform this action"

  Scenario: orgAdmin can manage their organization details only
    Given "john@harvard.edu" is an orgAdmin for "Harvard University"
    And I am signed in as "john@harvard.edu"
    When I update the "Harvard University" organization name to "Harvard Business School"
    Then the organization name should be "Harvard Business School"
    And I should see "Organization updated successfully"

  Scenario: Non-orgAdmin instructor cannot assign orgAdmin roles
    Given "jane@harvard.edu" is an instructor but not an orgAdmin for "Harvard University"
    And I am signed in as "jane@harvard.edu"
    When I try to assign "john@harvard.edu" as orgAdmin for "Harvard University"
    Then I should see "You are not authorized to perform this action"
    And "john@harvard.edu" should not be an orgAdmin

  Scenario: Student cannot access orgAdmin functions for their organization
    Given I am signed in as "student@harvard.edu"
    When I try to access the organization admin panel for "Harvard University"
    Then I should see "You are not authorized to perform this action"

  Scenario: orgAdmin can view their organization dashboard
    Given "john@harvard.edu" is an orgAdmin for "Harvard University"
    And I am signed in as "john@harvard.edu"
    When I visit the organization admin dashboard for "Harvard University"
    Then I should see organization statistics for "Harvard University"
    And I should see "Manage Organization"
    And I should see "Manage Terms"
    And I should see "Manage Courses"
    And I should see "Org Admins"

  Scenario: orgAdmin from different organization cannot manage other organizations
    Given another organization "MIT" with domain "mit.edu" exists
    And a user "admin@mit.edu" is an orgAdmin for "MIT"
    And I am signed in as "admin@mit.edu"
    When I try to manage "Harvard University"
    Then I should see "You are not authorized to perform this action"

  Scenario: orgAdmin cannot assign users from other organizations as orgAdmin
    Given "john@harvard.edu" is an orgAdmin for "Harvard University"
    And another organization "MIT" with domain "mit.edu" exists
    And a user "prof@mit.edu" with role "instructor" exists in "MIT"
    And I am signed in as "john@harvard.edu"
    When I try to assign "prof@mit.edu" as orgAdmin for "Harvard University"
    Then I should see "You are not authorized to perform this action"
