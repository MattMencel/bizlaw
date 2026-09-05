Feature: Exhibits ride the Offer
  An Exhibit cannot be played alone. It rides a staged Offer and costs a point
  of the exchange half on commit, and the half is the brake: it does not carry
  to the next Day, so the number of Offers caps total plays and a Team that
  hoards its Exhibits physically cannot dump them.

  Three rules decide what a played Exhibit is worth, and all three are
  independent of whether it was worth playing. It moves the opposing Client only
  where the Offer touches the Terms it bears on. Its shift is clipped to the
  travel that Client has left. And the document reaches the other Side at the
  instant the Offer commits — flagged as served and carrying no Exhibit property
  at all, because service gives a Team knowledge and never ammunition.

  Background:
    Given the reference Case has been imported
    And a Section at Western Illinois University
    And the Instructor creates a Simulation of the reference Case
    And Dana is on the plaintiff Side
    And Ravi is on the defendant Side

  Scenario: A relevant Exhibit on a flat Day and an irrelevant one on a closing Day
    Given Dana spends a request_documents on Day 1
    And Ravi spends a depose_witness on Day 1
    And Day 2 opens
    And Day 3 opens

    Given Priya spends a consult_client on Day 2 for the plaintiff Side
    And Dana stages an Offer on Day 2 of
      | term  | amount |
      | money | 45000  |
    And Dana attaches "The claimant's personnel file" to the Offer on Day 2
    When Priya seconds the plaintiff Offer on Day 2
    Then the plaintiff Side has 7 preparation points and 0 exchange points left on Day 2
    And the defendant Client has moved 0.2 of its bound

    Given Day 7 opens
    And Kofi spends a consult_client on Day 7 for the defendant Side
    And Ravi stages an Offer on Day 7 of
      | term | amount |
      | nda  |        |
    And Ravi attaches "Deposition of the plant supervisor" to the Offer on Day 7
    When Kofi seconds the defendant Offer on Day 7
    Then the defendant Side has 1 preparation points and 1 exchange points left on Day 7
    And the plaintiff Client has moved none of its bound

    Then the plaintiff Case File holds "The claimant's personnel file" as found
    And the plaintiff has spent "The claimant's personnel file"
    And the plaintiff Case File holds "Deposition of the plant supervisor" as served
    And the defendant Case File holds "Deposition of the plant supervisor" as found
    And the defendant has spent "Deposition of the plant supervisor"
    And the defendant Case File holds "The claimant's personnel file" as served

  Scenario: A half that cannot cover the Offer and the Exhibit refuses both
    Given Dana spends a request_documents on Day 1
    And Day 2 opens
    And Priya spends a consult_client on Day 2 for the plaintiff Side
    And the plaintiff exchange half has one point left on Day 2
    And Dana stages an Offer on Day 2 of
      | term  | amount |
      | money | 45000  |
    And Dana attaches "The claimant's personnel file" to the Offer on Day 2
    Then committing the plaintiff Offer on Day 2 is refused for want of Budget
    And the plaintiff may play "The claimant's personnel file"
    And the defendant Case File is empty
    And the defendant Client has moved none of its bound
