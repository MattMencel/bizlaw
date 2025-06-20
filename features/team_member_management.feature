Feature: Team Member Management
  As a team owner or manager
  I want to manage team members using bulk operations
  So that I can efficiently control who has access to the team

  Background:
    Given I am a logged in user
    And I am the owner of "Project Team"
    And the following users exist:
      | email             | first_name | last_name |
      | john@example.com  | John       | Doe       |
      | jane@example.com  | Jane       | Smith     |
      | bob@example.com   | Bob        | Wilson    |
      | alice@example.com | Alice      | Cooper    |

  Scenario: Bulk adding multiple team members
    When I bulk add the following users to "Project Team":
      | email             | role    |
      | john@example.com  | member  |
      | jane@example.com  | manager |
    Then I should see a success message "Successfully added 2 team members"
    And "John Doe" should be listed as a member of "Project Team"
    And "Jane Smith" should be listed as a manager of "Project Team"

  Scenario: Bulk adding with mixed roles
    When I bulk add the following users to "Project Team" with role "member":
      | email             |
      | john@example.com  |
      | bob@example.com   |
    Then I should see a success message "Successfully added 2 team members"
    And "John Doe" should be listed as a member of "Project Team"
    And "Bob Wilson" should be listed as a member of "Project Team"

  Scenario: Bulk removing multiple team members
    Given the following users are members of "Project Team":
      | email             | role    |
      | john@example.com  | member  |
      | jane@example.com  | member  |
      | bob@example.com   | manager |
    When I bulk remove the following members from "Project Team":
      | email             |
      | john@example.com  |
      | jane@example.com  |
    Then I should see a success message "Successfully removed 2 team members"
    And "John Doe" should not be listed as a member of "Project Team"
    And "Jane Smith" should not be listed as a member of "Project Team"
    And "Bob Wilson" should be listed as a manager of "Project Team"

  Scenario: Select All/None functionality for adding members
    When I visit the add team members page for "Project Team"
    And I click "Select All"
    Then all available students should be selected
    When I click "Select None"
    Then no students should be selected

  Scenario: Select All/None functionality for removing members
    Given the following users are members of "Project Team":
      | email             | role    |
      | john@example.com  | member  |
      | jane@example.com  | member  |
    When I visit the team page for "Project Team"
    And I click "Select All" in the members section
    Then all team members should be selected for removal
    When I click "Select None" in the members section
    Then no team members should be selected for removal

  Scenario: Cannot bulk add without selecting any users
    When I visit the add team members page for "Project Team"
    And I click "Add Selected Members" without selecting any users
    Then I should see an error message "Please select at least one student"

  Scenario: Cannot bulk remove without selecting any members
    Given the following users are members of "Project Team":
      | email             | role    |
      | john@example.com  | member  |
    When I visit the team page for "Project Team"
    And I click "Remove Selected" without selecting any members
    Then I should see an error message "Please select at least one team member"

  Scenario: Manager can perform bulk operations
    Given I am a manager of "Project Team"
    When I bulk add the following users to "Project Team":
      | email             | role    |
      | john@example.com  | member  |
    Then I should see a success message "Successfully added 1 team member"
    And "John Doe" should be listed as a member of "Project Team"

  Scenario: Regular member cannot perform bulk operations
    Given I am a regular member of "Project Team"
    When I try to access the bulk add members page
    Then I should see an error message "You are not authorized to perform this action"

  Scenario: Page loads without real-time refresh components
    When I visit the team page for "Project Team"
    Then I should not see any auto-refreshing components
    And the page should not make background requests

  Scenario: Viewing team member list without activity section
    Given "Project Team" has the following members:
      | email            | role    |
      | john@example.com | member  |
      | jane@example.com | manager |
    When I visit the team page for "Project Team"
    Then I should see the following team members:
      | name       | role    |
      | John Doe   | member  |
      | Jane Smith | manager |
    And I should not see a "Recent Activity" section

  Scenario: Cannot add the same user twice in bulk operation
    Given "John Doe" is a member of "Project Team"
    When I try to bulk add "john@example.com" to "Project Team"
    Then the user should not appear in the available students list
