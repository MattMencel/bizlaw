Feature: Team Member Management
  As a team owner or manager
  I want to manage team members
  So that I can control who has access to the team

  Background:
    Given I am a logged in user
    And I am the owner of "Project Team"
    And the following users exist:
      | email             | first_name | last_name |
      | john@example.com  | John       | Doe       |
      | jane@example.com  | Jane       | Smith     |
      | bob@example.com   | Bob        | Wilson    |

  Scenario: Adding a new team member
    When I add "john@example.com" as a member to "Project Team"
    Then I should see a success message "Member was successfully added to the team"
    And "John Doe" should be listed as a member of "Project Team"

  Scenario: Promoting a member to manager
    Given "Jane Smith" is a member of "Project Team"
    When I change the role of "Jane Smith" to "manager"
    Then I should see a success message "Member role was successfully updated"
    And "Jane Smith" should be listed as a manager of "Project Team"

  Scenario: Removing a team member
    Given "Bob Wilson" is a member of "Project Team"
    When I remove "Bob Wilson" from "Project Team"
    Then I should see a success message "Member was successfully removed from the team"
    And "Bob Wilson" should not be listed as a member of "Project Team"

  Scenario: Cannot remove team owner
    Given I am a manager of "Project Team"
    When I try to remove the team owner
    Then I should see an error message "Cannot remove team owner's membership"

  Scenario: Manager adding new members
    Given I am a manager of "Project Team"
    When I add "bob@example.com" as a member to "Project Team"
    Then I should see a success message "Member was successfully added to the team"
    And "Bob Wilson" should be listed as a member of "Project Team"

  Scenario: Regular member cannot manage team
    Given I am a regular member of "Project Team"
    When I try to add "john@example.com" as a member
    Then I should see an error message "You are not authorized to perform this action"

  Scenario: Viewing team member list
    Given "Project Team" has the following members:
      | email            | role    |
      | john@example.com | member  |
      | jane@example.com | manager |
    When I visit the team members page for "Project Team"
    Then I should see the following team members:
      | name       | role    |
      | John Doe   | member  |
      | Jane Smith | manager |

  Scenario: Cannot add the same user twice
    Given "John Doe" is a member of "Project Team"
    When I try to add "john@example.com" as a member
    Then I should see an error message "User is already a member of this team"
