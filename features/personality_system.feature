Feature: Personality System for Client Responses
  As a legal simulation instructor
  I want clients to have distinct personalities that influence their responses
  So that students experience realistic and varied client interactions

  Background:
    Given I am logged in as an instructor
    And there is a sexual harassment case with teams assigned

  Scenario: Case automatically assigns personalities to clients
    When I create a new sexual harassment case
    Then the plaintiff client should have a personality assigned
    And the defendant client should have a personality assigned
    And the personalities should be different from each other

  Scenario: Personality influences client feedback tone
    Given the plaintiff client has an "aggressive" personality
    And the defendant makes a low settlement offer
    When I generate client feedback for the offer
    Then the feedback should use assertive and demanding language
    And the satisfaction score should reflect aggressive expectations

  Scenario: Personality influences mood calculations
    Given the plaintiff client has a "cautious" personality
    And the defendant makes a reasonable settlement offer
    When I generate client feedback for the offer
    Then the mood should be more positive than for an aggressive personality
    And the feedback should express measured satisfaction

  Scenario: Personality consistency across multiple responses
    Given the plaintiff client has an "emotional" personality
    When I generate multiple client feedbacks during the simulation
    Then all responses should maintain emotional language patterns
    And the personality traits should be consistent across rounds

  Scenario: Different personality types generate distinct responses
    Given there are cases with different client personalities
    When I generate feedback for the same settlement offer across all cases
    Then each personality should produce distinctly different responses
    And the language patterns should be personality-appropriate

  Scenario: Personality influences satisfaction thresholds
    Given the plaintiff client has a "perfectionist" personality
    And the defendant client has a "pragmatic" personality
    When both receive the same settlement offer
    Then the perfectionist should have lower satisfaction
    And the pragmatic client should have higher satisfaction

  Scenario: Instructor can view client personalities
    Given I have a case with assigned client personalities
    When I view the case details
    Then I should see the plaintiff client's personality type
    And I should see the defendant client's personality type
    And I should see personality trait descriptions