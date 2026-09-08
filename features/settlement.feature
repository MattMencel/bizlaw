Feature: A settlement ends the run, and the instrument is executed
  An Acceptance is one of exactly two ways a run ends — the other is Arbitration
  when the Days run out. It closes the Day it lands on through the one close
  path, and that close opens nothing: a settled run hands out no further Action
  Budget, and every seam that asks whether a Day is closed asks whether the run
  has settled too. What the two Teams are left reading is the accepted Offer's
  own term sheet, executed, with each Team's own Client speaking over it.

  Background:
    Given the reference Case has been imported
    And a Section at Western Illinois University
    And the Instructor creates a Simulation of the reference Case
    And Dana is on the plaintiff Side
    And Ravi is on the defendant Side

  Scenario: A commit closes Day 3, an Acceptance on Day 4 ends the run, and Day 5 never opens
    Given both Sides commit Day 1
    And both Sides commit Day 2
    And Kofi spends a consult_client on Day 3 for the defendant Side
    And Ravi commits Day 3
    And Priya spends a consult_client on Day 3 for the plaintiff Side
    And Dana stages an Offer on Day 3 of
      | term    | amount |
      | money   | 45000  |
      | apology |        |
    When Priya seconds the plaintiff Offer on Day 3
    Then Days 1 to 3 have closed
    And Day 4 is open with 8 preparation points and 2 exchange points for each Side
    When Ravi takes the plaintiff Offer from Day 3 on Day 4, seconded by Kofi
    Then Days 1 to 4 have closed
    And the Simulation has settled
    And Day 5 was never opened

  Scenario: A settled run refuses the acts a live one allows
    Given Priya spends a consult_client on Day 1 for the plaintiff Side
    And Dana stages an Offer on Day 1 of
      | term  | amount |
      | money | 45000  |
    And Priya seconds the plaintiff Offer on Day 1
    And Kofi spends a consult_client on Day 1 for the defendant Side
    When Ravi takes the plaintiff Offer from Day 1 on Day 1, seconded by Kofi
    Then the Simulation has settled
    And a consult_client on Day 1 is refused because the_simulation_has_settled
    And staging an Offer on Day 1 is refused, because the run has ended
    And committing Day 1 is refused, because the run has ended

  Scenario: Both Teams read one instrument, and each hears its own Client
    Given Priya spends a consult_client on Day 1 for the plaintiff Side
    And Dana stages an Offer on Day 1 of
      | term    | amount |
      | money   | 45000  |
      | apology |        |
    And Priya seconds the plaintiff Offer on Day 1
    And Kofi spends a consult_client on Day 1 for the defendant Side
    When Ravi takes the plaintiff Offer from Day 1 on Day 1, seconded by Kofi
    Then the executed instrument reads
      | term    | amount |
      | money   | 45000  |
      | apology |        |
    And it is the same term sheet for both Teams
    And it carries Dana's signature and Ravi's countersignature
    And the plaintiff Client says their line for having it taken
    And the defendant Client says their line for taking it
    And neither Client shows a Reaction Band
    And each Team sees its own Client's face, and they are two different people
