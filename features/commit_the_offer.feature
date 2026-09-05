Feature: A Team commits its Offer and the exchange half pays for it
  Committing an Offer is a Boardroom act, at most one per Side per Day, and it
  costs one point of the exchange half — the half that buys an Offer and the
  Exhibits riding it and nothing else. It is gated by the Second, and only the
  Instructor's waiver substitutes for one. Committing an Offer implies the Day
  commit; the reverse does not follow. The other Side can take the deal, gated
  by its own Second, and taking it costs nothing.

  Background:
    Given the reference Case has been imported
    And a Section at Western Illinois University
    And the Instructor creates a Simulation of the reference Case
    And Dana is on the plaintiff Side
    And Ravi is on the defendant Side

  Scenario: An Offer lands on a flat Day, and a second one cannot follow it
    Given Priya spends a consult_client on Day 1 for the plaintiff Side
    And Dana stages an Offer on Day 1 of
      | term    | amount |
      | money   | 45000  |
      | apology |        |
    When Priya seconds the plaintiff Offer on Day 1
    Then the committed plaintiff Offer on Day 1 reads
      | term    | amount |
      | apology |        |
      | money   | 45000  |
    And the plaintiff Side has 7 preparation points and 1 exchange points left on Day 1
    And the plaintiff Side has committed Day 1
    When Dana stages an Offer on Day 1 of
      | term  | amount |
      | money | 42000  |
    Then committing the plaintiff Offer on Day 1 again is refused
    And the plaintiff Side has 7 preparation points and 1 exchange points left on Day 1

  Scenario: A Team alone holds a dead control until the Instructor opens it
    Given Dana stages an Offer on Day 1 of
      | term  | amount |
      | money | 45000  |
    Then committing the plaintiff Offer on Day 1 is refused for want of a Second
    When the Instructor waives the plaintiff Second on Day 1
    And Dana commits the plaintiff Offer on Day 1 under the waiver
    Then the committed plaintiff Offer on Day 1 reads
      | term  | amount |
      | money | 45000  |
    And the committed plaintiff Offer on Day 1 names nobody as its Second

  Scenario: The other Side takes the deal, gated by its own Second
    Given Priya spends a consult_client on Day 1 for the plaintiff Side
    And Dana stages an Offer on Day 1 of
      | term  | amount |
      | money | 45000  |
    And Priya seconds the plaintiff Offer on Day 1
    And Kofi spends a consult_client on Day 1 for the defendant Side
    When Ravi accepts the plaintiff Offer on Day 1, seconded by Kofi
    Then the plaintiff Offer on Day 1 has been accepted by Ravi
    And the defendant Side has spent nothing on the exchange half on Day 1
