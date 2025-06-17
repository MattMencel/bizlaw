Feature: Case creation by admin or instructor
  As an admin or instructor
  I want to create a new case with a title and description
  So that I can set up simulations for teams in my courses

  Background:
    Given I am logged in as an admin or instructor
    And I belong to an organization "University of Business Law"
    And I have a course "Business Law 101" in my organization

  Scenario: Successful case creation
    When I navigate to the new case page
    And I select the course "Business Law 101"
    And I enter a title and description for the case
    And I assign teams from the selected course
    And I submit the form
    Then I should see a confirmation that the case was created
    And the new case should appear in the case list for the course
    And the case should be associated with the selected course
