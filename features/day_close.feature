Feature: A Day closes and the next one opens
  A Side commits its Day by declaring itself finished with it. A Day closes when
  both Sides have committed it, when the Instructor's deadline fires, or when
  the Instructor force-closes it — three callers and one close. Remaining Budget
  expires at close: neither half carries, and the next Day's row is written
  fresh from the quota.

  Background:
    Given the reference Case has been imported
    And a Section at Western Illinois University
    And the Instructor creates a Simulation of the reference Case
    And Dana is on the plaintiff Side
    And Ravi is on the defendant Side

  Scenario: Three Days played end to end, spending on each
    When Dana spends a depose_witness on Day 1
    And Ravi spends a request_documents on Day 1
    And both Sides commit Day 1
    And Dana spends a retain_expert on Day 2
    And Ravi spends a consult_client on Day 2
    And both Sides commit Day 2
    And Dana spends a research_precedent on Day 3
    And Ravi spends a manage_press on Day 3
    And both Sides commit Day 3
    Then Days 1 to 3 have closed
    And Day 4 is open with 8 preparation points and 2 exchange points for each Side
    And the plaintiff Docket holds 3 entries

  Scenario: The Day stays open while one Side has not finished
    When Dana commits Day 1
    Then Day 1 is open
    And Day 2 has no Budget yet

  Scenario: The Instructor force-closes a stalled Day
    When Dana commits Day 1
    And the Instructor force-closes Day 1
    Then Days 1 to 1 have closed
    And Day 2 is open with 8 preparation points and 2 exchange points for each Side

  Scenario: A deadline that fires closes the Day exactly as a second commit would
    Given Day 1 runs to "2026-03-02 17:00"
    When the deadline sweep runs at "2026-03-02 17:01"
    Then Days 1 to 1 have closed
    And Day 2 is open with 8 preparation points and 2 exchange points for each Side

  Scenario: The Instructor extends a deadline that has not yet fired
    Given Day 1 runs to "2026-03-02 17:00"
    When the Instructor extends Day 1 to "2026-03-03 17:00"
    And the deadline sweep runs at "2026-03-02 17:01"
    Then Day 1 is open

  Scenario: Budget left on a closed Day is gone
    When both Sides commit Day 1
    Then a consult_client on Day 1 is refused because the_day_has_closed

  Scenario: The last Day closes without opening one that does not exist
    When every Day up to Day 10 is committed by both Sides
    Then Days 1 to 10 have closed
    And the Simulation has no Day 11
