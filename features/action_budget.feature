Feature: A Day opens with both halves of the Action Budget
  A Team's Action Budget arrives in two halves each Day and neither half carries.
  The preparation half is ungated and buys everything that is not an Offer; the
  exchange half is an absolute number of points. Past a knee at three fifths of
  the Simulation the shape of the Day changes — little left to prepare, more to
  trade.

  Background:
    Given the reference Case has been imported
    And a Section at Western Illinois University

  Scenario: Day 1 arrives with the flat Budget
    When the Instructor creates a Simulation of the reference Case
    Then each Side has 8 preparation points and 2 exchange points on Day 1

  Scenario: The closing Days trade preparation allowance for exchange
    When the Instructor creates a Simulation of the reference Case
    And Day 7 opens
    Then each Side has 2 preparation points and 3 exchange points on Day 7

  Scenario: A Day already opened keeps the quota it was written with
    When the Instructor creates a Simulation of the reference Case
    And the Section doubles its Action Budget
    Then each Side has 8 preparation points and 2 exchange points on Day 1
