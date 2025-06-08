Feature: Case Management
  As a student
  I want to work on legal cases
  So that I can practice and improve my legal skills

  Background:
    Given I am signed in
    And I am a member of a team

  Scenario: Starting a new case
    Given there is a case type "Contract Analysis"
    When I start a new case with the following details:
      | Case Type | Contract Analysis |
      | Team      | My Team          |
    Then I should see a success message "Case was successfully created"
    And the case should be in "not_started" status

  Scenario: Viewing active cases
    Given the following cases exist:
      | Case Type         | Team     | Status      |
      | Contract Analysis | Team One | in_progress |
      | Tort Law         | Team Two | submitted   |
    When I visit the cases page
    Then I should see the following cases:
      | Case Type         | Team     | Status      |
      | Contract Analysis | Team One | In Progress |
      | Tort Law         | Team Two | Submitted   |

  Scenario: Updating case status
    Given I have an active case "Contract Analysis"
    When I update the case status to "in_progress"
    Then I should see a success message "Case status was successfully updated"
    And the case status should be "In Progress"

  Scenario: Adding notes to case
    Given I have an active case "Contract Analysis"
    When I add the following note to the case:
      """
      Identified key contract clauses that need analysis.
      Next steps: Review precedent cases and prepare summary.
      """
    Then the note should be visible in the case timeline

  Scenario: Submitting case for review
    Given I have an active case "Contract Analysis"
    And I have completed all required tasks
    When I submit the case for review
    Then I should see a success message "Case was submitted for review"
    And the case should be in "submitted" status

  Scenario: Completing a case
    Given there is a case "Contract Analysis" under review
    And I am an instructor
    When I mark the case as completed
    Then I should see a success message "Case was marked as completed"
    And the case should be in "completed" status

  Scenario: Filtering cases
    Given the following cases exist:
      | Case Type         | Team     | Status      |
      | Contract Analysis | Team One | in_progress |
      | Tort Law         | Team Two | completed   |
      | Property Law     | Team One | not_started |
    When I filter cases by status "in_progress"
    Then I should only see cases with status "In Progress"

  Scenario: Case deadline warning
    Given I have a case due in 2 days
    When I visit the cases page
    Then I should see a warning message "Case deadline approaching"

  Scenario: Viewing case analytics
    Given I have completed multiple cases
    When I visit the case analytics page
    Then I should see statistics about my case performance
