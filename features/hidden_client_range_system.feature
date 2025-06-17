# Hidden Client Range System - BDD Feature Stories

@hidden_client_ranges
Feature: Hidden Client Range System
  As a legal education platform
  We want to provide realistic client feedback based on hidden settlement ranges
  So that students learn to manage client expectations and make strategic decisions

  Background:
    Given I belong to an organization "University of Business Law"
    And I am enrolled in a course "Advanced Business Law"
    And the system has a sexual harassment case "Mitchell v. TechFlow Industries" in this course
    And the case has plaintiff team "Mitchell Legal Team" from this course
    And the case has defendant team "TechFlow Defense Team" from this course
    And both teams have been assigned to the case
    And the simulation has configured hidden client ranges
    And the ranges are set to realistic but undisclosed values

@range_validation
Feature: Client Range Validation and Feedback
  As the simulation system
  I want to validate settlement offers against hidden client ranges
  So that realistic client feedback can be generated

  Scenario Outline: Validate plaintiff settlement offers against hidden ranges
    Given I am a member of the plaintiff team
    And the plaintiff has configured hidden minimum and ideal amounts
    When I submit a settlement demand <relative_to_range>
    Then I should receive client feedback with mood <expected_mood>
    And the satisfaction score should be <satisfaction_range>
    And the feedback message should indicate <feedback_theme>

    Examples:
      | relative_to_range    | expected_mood | satisfaction_range | feedback_theme |
      | well_above_ideal     | unhappy       | 20-40             | too_aggressive |
      | near_ideal           | satisfied     | 80-90             | strong_position |
      | between_min_ideal    | satisfied     | 70-85             | reasonable_opening |
      | near_minimum         | neutral       | 55-70             | conservative_approach |
      | below_minimum        | very_unhappy  | 10-25             | below_minimum |

  Scenario Outline: Validate defendant settlement offers against hidden ranges
    Given I am a member of the defendant team
    And the defendant has configured hidden ideal and maximum amounts
    When I submit a counteroffer <relative_to_range>
    Then I should receive client feedback with mood <expected_mood>
    And the satisfaction score should be <satisfaction_range>
    And the feedback message should indicate <feedback_theme>

    Examples:
      | relative_to_range    | expected_mood | satisfaction_range | feedback_theme |
      | below_ideal          | satisfied     | 85-95             | excellent_position |
      | at_ideal             | satisfied     | 80-90             | ideal_amount |
      | between_ideal_max    | neutral       | 60-75             | acceptable_compromise |
      | near_maximum         | unhappy       | 35-50             | concerning_amount |
      | exceeds_maximum      | very_unhappy  | 10-25             | exceeds_maximum |

@dynamic_range_adjustment
Feature: Dynamic Range Adjustment Based on Events
  As the simulation system
  I want to adjust hidden client ranges based on simulation events
  So that the negotiation reflects changing circumstances

  Scenario: Media attention increases plaintiff expectations
    Given the plaintiff has configured hidden ranges
    And we are in round 3 of the negotiation
    When the "media attention" event triggers
    Then the plaintiff's minimum acceptable should increase significantly
    And the plaintiff's ideal amount should increase proportionally
    And future offers should be validated against the new ranges

  Scenario: Additional evidence strengthens plaintiff position
    Given the plaintiff has configured hidden ranges
    When the "additional evidence" event triggers with strength "high"
    Then the plaintiff's minimum acceptable should increase substantially
    And the plaintiff's ideal amount should increase proportionally
    And the plaintiff team should receive feedback: "Client more confident about case strength with new evidence"

  Scenario: IPO pressure increases defendant willingness to settle
    Given the defendant has configured hidden ranges
    When the "IPO delay" event triggers
    Then the defendant's maximum acceptable should increase substantially
    And the defendant's ideal amount should increase proportionally
    And the defendant team should receive feedback: "Client urgently wants resolution before IPO"

@client_mood_tracking
Feature: Client Mood and Satisfaction Tracking
  As a student team
  I want to see how my client's mood changes based on my negotiation decisions
  So that I can adjust my strategy to maintain client satisfaction

  Scenario: Track client mood progression over multiple rounds
    Given I am a member of the plaintiff team
    And I have submitted the following offers over multiple rounds:
      | Round | Relative Position | Expected Mood |
      | 1     | above_ideal      | neutral       |
      | 2     | at_ideal         | satisfied     |
      | 3     | near_ideal       | satisfied     |
      | 4     | between_ranges   | neutral       |
    When I view my client mood dashboard
    Then I should see the mood progression over time
    And I should see satisfaction trend indicators
    And I should receive strategic guidance based on mood patterns

  Scenario: Receive escalating pressure feedback as offers move away from ideal
    Given I am a member of the defendant team
    And the defendant has configured ideal amount
    When I submit a series of increasing offers:
      | Round | Relative Position | Expected Feedback Theme |
      | 1     | below_ideal      | "Client pleased with conservative approach" |
      | 2     | above_ideal      | "Client concerned about increased exposure" |
      | 3     | mid_range        | "Client getting nervous about settlement cost" |
      | 4     | near_maximum     | "Client very worried about financial impact" |
    Then each round should show increasing client concern
    And I should receive warnings about approaching the maximum acceptable range

@settlement_gap_analysis
Feature: Settlement Gap Analysis and Strategic Guidance
  As the simulation system
  I want to analyze the gap between team positions
  So that I can provide strategic guidance without revealing opponent ranges

  Scenario: Provide guidance when teams are far apart
    Given the plaintiff has offered significantly above their ideal
    And the defendant has offered at their ideal amount
    And there is a substantial settlement gap
    When the system analyzes the negotiation status
    Then both teams should receive feedback about the large gap
    And the plaintiff should get hints about "considering more realistic opening positions"
    And the defendant should get hints about "showing good faith with meaningful movement"
    But neither team should see the opponent's acceptable ranges

  Scenario: Indicate when settlement zone overlap exists
    Given the plaintiff and defendant ranges allow for potential overlap
    And current offers are within the overlapping zone
    When the system analyzes settlement potential
    Then both teams should receive subtle encouragement
    And feedback should suggest "productive negotiation zone emerging"
    But the exact ranges should remain hidden

@instructor_range_management
Feature: Instructor Management of Client Ranges
  As an instructor
  I want to set and adjust hidden client ranges for simulations
  So that I can create realistic and educational negotiation scenarios

  Scenario: Set initial client ranges when creating simulation
    Given I am logged in as an instructor
    And I am creating a new sexual harassment simulation
    When I configure the simulation parameters
    Then I should be able to set:
      | Parameter | Field | Relationship |
      | Plaintiff minimum acceptable | plaintiff_min_acceptable | Base amount |
      | Plaintiff ideal amount | plaintiff_ideal | Multiple of minimum |
      | Defendant ideal amount | defendant_ideal | Fraction of plaintiff minimum |
      | Defendant maximum acceptable | defendant_max_acceptable | Between plaintiff minimum and ideal |
    And the system should validate that ranges are logically consistent
    And students should never see these values directly

  Scenario: Adjust ranges mid-simulation for educational purposes
    Given I have an active simulation with established ranges
    When I access the instructor simulation controls
    And I increase the plaintiff's minimum acceptable by a specified percentage
    Then the change should take effect for future offer evaluations
    And students should receive appropriate feedback reflecting the change
    And the adjustment should be logged for post-simulation analysis

@feedback_personalization
Feature: Personalized Client Feedback Based on Ranges
  As a student
  I want to receive personalized client feedback that feels realistic
  So that I can develop better client counseling and negotiation skills

  Scenario: Receive contextual feedback based on offer positioning
    Given I am representing the plaintiff
    And I submit an offer within the satisfied range for my client
    When the system generates client feedback
    Then I should receive feedback like:
      """
      Client is pleased with this strategic positioning. This amount reflects 
      the strength of our case while showing reasonable expectations for settlement. 
      Client is optimistic about defendant's response.
      """
    And the feedback should not mention specific dollar amounts as thresholds

  Scenario: Receive pressure feedback when approaching client limits
    Given I am representing the defendant
    And I submit an offer approaching my client's maximum acceptable limit
    When the system generates client feedback
    Then I should receive escalating pressure feedback like:
      """
      Client is getting very concerned about the settlement amount. This is 
      approaching the upper limits of what the company can justify to shareholders. 
      Client strongly prefers to resolve this matter soon.
      """
    And I should see visual indicators of increased client pressure

@range_confidentiality
Feature: Range Confidentiality and Information Security
  As the educational platform
  I want to ensure that hidden client ranges remain confidential
  So that the simulation maintains its educational integrity

  Scenario: Verify ranges are not exposed in client-side code
    Given I am a student accessing the simulation
    When I inspect the browser developer tools
    Then I should not see any opponent range information
    And I should not see my own client's exact threshold numbers
    And all sensitive range data should be server-side only

  Scenario: Ensure feedback doesn't leak range information
    Given I receive client feedback on my settlement offer
    When I analyze the feedback message content
    Then the feedback should not contain exact dollar thresholds
    And the feedback should not reveal opponent acceptable ranges
    And the feedback should use qualitative rather than quantitative language

  Scenario: Verify instructor-only access to range data
    Given I am a student in a simulation
    When I attempt to access range configuration endpoints
    Then I should receive an authorization error
    And only instructor-role users should have access to range data
    And all range access should be logged for security auditing