Feature: The Actions a Team bought land
  Preparation pays off on a schedule the Team chose. An Action spent on Day 1
  with a lead time of two produces its documents when Day 3 opens, and they fill
  the Case File — what we know, as against the Docket's what we have done.

  A document may carry an Exhibit, and whether that Exhibit is favorable is read
  off who found it. One pointing at the other Side's Client is held to be played
  later; one pointing at your own is not playable at all and lands the moment it
  is discovered, moving your own Client toward realism.

  Background:
    Given the reference Case has been imported
    And a Section at Western Illinois University
    And the Instructor creates a Simulation of the reference Case
    And Dana is on the plaintiff Side
    And Sam is on the defendant Side

  Scenario: Deposing a witness on Day 1 fills the Case File on Day 3
    When Sam spends a depose_witness on Day 1
    And Day 2 opens
    Then the defendant Case File is empty
    When Day 3 opens
    Then the defendant Case File holds "Deposition of the plant supervisor"
    And the defendant may play "Deposition of the plant supervisor"
    And the defendant Client has moved none of its bound
    And the plaintiff Client has moved none of its bound

  Scenario: The same deposition, found by the Side it hurts, lands at once
    When Dana spends a depose_witness on Day 1
    And Day 2 opens
    And Day 3 opens
    Then the plaintiff Case File holds "Deposition of the plant supervisor"
    And the plaintiff may not play "Deposition of the plant supervisor"
    And the plaintiff Client has moved 0.25 of its bound

  Scenario: A Day opened twice moves the bound once
    When Dana spends a depose_witness on Day 1
    And Day 2 opens
    And Day 3 opens
    And Day 3 opens
    Then the plaintiff Case File holds "Deposition of the plant supervisor"
    And the plaintiff Client has moved 0.25 of its bound
