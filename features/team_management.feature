Feature: Team Management
  As a user
  I want to manage teams within my course
  So that I can collaborate with other users

  Background:
    Given I am a logged in user
    And I belong to an organization "University of Business Law"
    And I am enrolled in a course "Business Law 101"
    And I have the following teams in this course:
      | name        | description          | max_members |
      | Alpha Team  | Main project team    | 5           |
      | Beta Team   | Secondary team       | 3           |

  Scenario: Creating a new team
    When I create a team with the following details:
      | name         | description       | max_members | course           |
      | Gamma Team   | New project team | 4           | Business Law 101 |
    Then I should see a success message "Team was successfully created"
    And I should be the owner of "Gamma Team"
    And the team should have 0 members
    And the team should be associated with my course

  Scenario: Viewing my teams
    When I visit the teams page
    Then I should see the following teams:
      | name       | description        | members |
      | Alpha Team | Main project team  | 1/5     |
      | Beta Team  | Secondary team     | 1/3     |

  Scenario: Updating team details
    Given I am the owner of "Alpha Team"
    When I update "Alpha Team" with the following details:
      | name        | description           | max_members |
      | Alpha Prime | Updated project team  | 6           |
    Then I should see a success message "Team was successfully updated"
    And the team details should be updated

  Scenario: Deleting a team
    Given I am the owner of "Beta Team"
    When I delete "Beta Team"
    Then I should see a success message "Team was successfully deleted"
    And "Beta Team" should not be visible in the teams list

  Scenario: Cannot exceed maximum team members
    Given "Alpha Team" has 5 members
    When I try to add a new member to "Alpha Team"
    Then I should see an error message "Team has reached maximum member limit"

  Scenario: Search for teams
    Given the following teams exist in my course:
      | name          | description     |
      | Dev Team      | Developers     |
      | Design Team   | Designers      |
      | DevOps Team   | Operations     |
    When I search for teams containing "Dev"
    Then I should see "Dev Team" in the results
    And I should see "DevOps Team" in the results
    But I should not see "Design Team" in the results
