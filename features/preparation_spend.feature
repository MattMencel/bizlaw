Feature: A Team spends its preparation half
  Every act in the Day enters through one command seam. A spend is irreversible
  and, unlike an Offer, ungated by a Second, so every spend is quoted before it
  lands — naming the cost, what the Side has left today, and the Day the result
  arrives on. The Docket answers what we have done and what is coming.

  Background:
    Given the reference Case has been imported
    And a Section at Western Illinois University
    And the Instructor creates a Simulation of the reference Case
    And Dana is on the plaintiff Side

  Scenario: A Consult and two Actions on Day 1, read back off the Docket
    When Dana spends a consult_client on Day 1
    And Dana spends a request_documents on Day 1
    And Dana spends a depose_witness on Day 1
    Then the plaintiff Side has 2 preparation points left on Day 1
    And the plaintiff Docket reads
      | action            | cost | spent by | lands on |
      | consult_client    | 1    | Dana     | 1        |
      | request_documents | 2    | Dana     | 2        |
      | depose_witness    | 3    | Dana     | 3        |

  Scenario: An Action the preparation half cannot cover is refused
    When Dana spends a retain_expert on Day 1
    And Dana spends a depose_witness on Day 1
    Then a retain_expert on Day 1 is refused because the_budget_cannot_cover_it
    And the plaintiff Side has 0 preparation points left on Day 1
    And the plaintiff Docket holds 2 entries

  Scenario: An Action whose result cannot arrive is refused
    When Day 10 opens
    Then a depose_witness on Day 10 is refused because the_result_would_land_past_the_last_day
