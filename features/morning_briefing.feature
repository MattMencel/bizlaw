Feature: The Morning Briefing and the Day's read surfaces
  A Day opens on the draft's front matter with what has just happened: the Actions
  that landed and the documents the other Side served. Beside them sits what the
  Team started with — the documents in hand at the open, the Client's opening
  statement, the calendar and the published Rubric — and one line of fixed copy
  naming the Day's grammar. Every section is composed by the engine from objects the
  Case already authors, so a briefing is never authored per Case.

  Three record surfaces sit alongside it, each answering its own question. The
  Docket is what we have done and what is coming, the Case File is what we know,
  and the Action Board is what we could do. The Terms Board shows the shape of
  the deal: the Team's own position, the other Side's last committed Offer, and
  the Client's stated aspiration — and never Par, because no rubric-derived
  number reaches a student before Release.

  The empty state is the tutorial. There is no first-run pass and no per-student
  progress, so an empty Docket says what a Docket would hold and a full Action
  Board says what an Action costs and when it lands. Everything is present from
  Day 1; only the Exhibit affordances gate, and they gate on what the Team holds.

  Background:
    Given the reference Case has been imported
    And a Section at Western Illinois University
    And the Instructor creates a Simulation of the reference Case
    And Dana is on the plaintiff Side
    And Ravi is on the defendant Side

  Scenario: Day 1 opens with only what the Team walked in with
    Then Dana's Morning Briefing on Day 1 reports nothing landed and nothing served
    And Dana's Morning Briefing on Day 1 starts her with
      | The termination letter    |
      | The claimant's own notes  |
    And Dana's Morning Briefing on Day 1 carries what her Client wants
      """
      Eleven years I gave them
      """
    And Dana's Morning Briefing on Day 1 carries all 10 Days
    And Dana's Morning Briefing on Day 1 names the Day's grammar
    And Dana's Morning Briefing on Day 1 carries the published Rubric
      | Settlement quality, 40 points |
      | Legal strategy, 30 points     |
      | Collaboration, 20 points      |
      | Efficiency, 10 points         |

  Scenario: The empty state is the tutorial, and the Action Board is not empty
    Then the plaintiff Docket says what a Docket would hold
    And the plaintiff Action Board on Day 1 prices every Action
      | consult_client     | 1 | 0 | 1 |
      | manage_press       | 2 | 1 | 2 |
      | request_documents  | 2 | 1 | 2 |
      | research_precedent | 2 | 1 | 2 |
      | depose_witness     | 3 | 2 | 3 |
      | retain_expert      | 5 | 2 | 3 |
    And the plaintiff Exhibit affordances are unavailable

  Scenario: The last Day still prices what it can no longer buy
    Given every Day up to Day 10 is committed by both Sides
    Then the plaintiff Action Board on Day 10 prices every Action
      | consult_client     | 1 | 0 | 10 |
      | manage_press       | 2 | 1 |    |
      | request_documents  | 2 | 1 |    |
      | research_precedent | 2 | 1 |    |
      | depose_witness     | 3 | 2 |    |
      | retain_expert      | 5 | 2 |    |

  Scenario: The Terms Board opens showing only what the Client wants
    Then the plaintiff Terms Board on Day 1 reads
      | money            |  |  | 250000 |
      | apology          |  |  | named  |
      | nda              |  |  |        |
      | reinstatement    |  |  | named  |
      | training         |  |  |        |
      | reference_letter |  |  |        |
      | policy_change    |  |  |        |
    And no read anywhere on Day 1 shows Dana a Par

  Scenario: Day 3 opens with what the Team's Actions landed
    Given Dana spends a depose_witness on Day 1
    And Dana spends a request_documents on Day 1
    When Day 2 opens
    And Day 3 opens
    Then Dana's Morning Briefing on Day 3 reports landed
      | Deposition of the plant supervisor |
    And Dana's Morning Briefing on Day 2 reports landed
      | The claimant's personnel file |
    And Dana's Morning Briefing on Day 3 starts her with
      | The termination letter   |
      | The claimant's own notes |
    And the plaintiff Docket has stopped explaining itself
    And the plaintiff Exhibit affordances have appeared

  Scenario: A Team is served an Exhibit and reads it in the next Briefing
    Given Ravi spends a depose_witness on Day 1
    And Day 2 opens
    And Day 3 opens
    And Kofi spends a consult_client on Day 3 for the defendant Side
    And Ravi stages an Offer on Day 3 of
      | term  | amount |
      | money | 45000  |
    And Ravi attaches "Deposition of the plant supervisor" to the Offer on Day 3
    When Kofi seconds the defendant Offer on Day 3
    Then Dana's Morning Briefing on Day 3 reports served
      | Deposition of the plant supervisor |
    And Dana's Morning Briefing on Day 3 hands her nothing she could play back
    And Dana's Morning Briefing on Day 3 reports nothing landed
    And the plaintiff Exhibit affordances are unavailable
    And the plaintiff Terms Board on Day 3 reads
      | money            |  | 45000 | 250000 |
      | apology          |  |       | named  |
      | nda              |  |       |        |
      | reinstatement    |  |       | named  |
      | training         |  |       |        |
      | reference_letter |  |       |        |
      | policy_change    |  |       |        |

  Scenario: A teammate returning from two Days away is given the same object, widened
    Given Dana spends a request_documents on Day 1
    When Day 2 opens
    And Dana spends a depose_witness on Day 2
    And Day 3 opens
    And Day 4 opens
    Then Priya's Morning Briefing on Day 4 since Day 2 covers 3 Days
    And Priya's Morning Briefing on Day 4 since Day 2 reports landed
      | The claimant's personnel file      |
      | Deposition of the plant supervisor |
    And Dana's Morning Briefing on Day 4 reports landed
      | Deposition of the plant supervisor |
