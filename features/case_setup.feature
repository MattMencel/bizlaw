Feature: Case creation by admin or instructor
  As an admin or instructor
  I want to create a new case with a title and description
  So that I can set up simulations for teams

  Scenario: Successful case creation
    Given I am logged in as an admin or instructor
    When I navigate to the new case page
    And I enter a title and description for the case
    And I submit the form
    Then I should see a confirmation that the case was created
    And the new case should appear in the case list
