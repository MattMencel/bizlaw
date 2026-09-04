Feature: A Team stages an Offer and nobody can commit it alone
  An Offer is staged before it is committed: visible to the whole Team,
  revisable, and costing nothing until it lands. The Second is the only gate
  inside a Team — an Offer lands only when a member other than the one who
  staged it confirms it — and it is never explained in advance. A student who
  stages one holds a commit control that is present and disabled, naming the
  teammates who can second it. A Team whose other members are absent is given
  the Instructor's waiver instead, for one Team and one Day.

  Background:
    Given the reference Case has been imported
    And a Section at Western Illinois University
    And the Instructor creates a Simulation of the reference Case
    And Dana is on the plaintiff Side

  Scenario: A position is put on the table, revised twice, and costs nothing
    When Dana stages an Offer on Day 1 of
      | term  | amount |
      | money | 45000  |
    And Dana revises the Offer on Day 1 to
      | term    | amount |
      | money   | 42000  |
      | apology |        |
    And Dana revises the Offer on Day 1 to
      | term          | amount |
      | money         | 40000  |
      | apology       |        |
      | reinstatement |        |
    Then the plaintiff Offer on Day 1 reads
      | term          | amount |
      | apology       |        |
      | money         | 40000  |
      | reinstatement |        |
    And the plaintiff Side has 8 preparation points and 2 exchange points left on Day 1
    And the plaintiff Docket holds no spends

  Scenario: The staging is on the Docket for a teammate to find
    When Dana stages an Offer on Day 1 of
      | term  | amount |
      | money | 45000  |
    Then the plaintiff Docket reads as acts
      | act          | by   | cost |
      | offer_staged | Dana |      |

  Scenario: The commit control names the teammates who can second it
    Given Priya spends a consult_client on Day 1 for the plaintiff Side
    When Dana stages an Offer on Day 1 of
      | term  | amount |
      | money | 45000  |
    Then the Offer on Day 1 can be seconded by Priya

  Scenario: A Team alone stages an Offer it cannot commit
    When Dana stages an Offer on Day 1 of
      | term  | amount |
      | money | 45000  |
    Then the Offer on Day 1 cannot be seconded at all

  Scenario: The Instructor waives the Second for one Team for one Day
    Given Dana stages an Offer on Day 1 of
      | term  | amount |
      | money | 45000  |
    When the Instructor waives the plaintiff Second on Day 1
    Then the Offer on Day 1 can be committed
    And the plaintiff Docket reads as acts
      | act           | by                 | cost |
      | offer_staged  | Dana               |      |
      | second_waived | Professor Adeyemi  |      |
    And the plaintiff Second is not waived on Day 2
    And no Offer names Professor Adeyemi as its seconder

  Scenario: The other Team's gate is untouched by the waiver
    When the Instructor waives the plaintiff Second on Day 1
    Then the defendant Second is not waived on Day 1

  Scenario: A discarded draft leaves nothing behind
    Given Dana stages an Offer on Day 1 of
      | term  | amount |
      | money | 45000  |
    When Dana discards the Offer on Day 1
    Then the plaintiff Side has no Offer on Day 1
    And the plaintiff Side has 8 preparation points and 2 exchange points left on Day 1
