Feature: AI-Enhanced Client Range Validation System
  As a legal simulation platform
  I want to provide AI-enhanced range validation for settlement offers
  So that students receive more contextual and realistic feedback about offer positioning

  Background:
    Given I belong to an organization "University of Business Law"
    And I am enrolled in a course "Advanced Business Law"
    And the system has a sexual harassment case "Mitchell v. TechFlow Industries" in this course
    And the case has plaintiff team "Mitchell Legal Team" from this course
    And the case has defendant team "TechFlow Defense Team" from this course
    And both teams have been assigned to the case
    And the simulation has 6 negotiation rounds configured
    And the Google AI service is configured and enabled
    And the simulation has the following ranges:
      | Role | Min Acceptable | Ideal | Max Acceptable |
      | Plaintiff | 150000 | 300000 | N/A |
      | Defendant | N/A | 75000 | 250000 |

  @ai_range_validation
  Scenario: AI-enhanced validation for plaintiff offer within ideal range
    Given I am a member of the "Mitchell Legal Team" (plaintiff)
    And I am in round 2 of the negotiation
    When I submit a settlement demand of $275000
    And the AI service enhances the range validation feedback
    Then I should receive AI-enhanced validation feedback
    And the feedback should indicate strong positioning
    And the feedback should reflect client satisfaction with strategic approach
    And the feedback should provide contextual guidance without revealing ranges
    And the feedback should maintain educational messaging

  @ai_range_validation
  Scenario: AI-enhanced validation for defendant offer exceeding maximum
    Given I am a member of the "TechFlow Defense Team" (defendant)
    And I am in round 3 of the negotiation
    When I submit a counteroffer of $275000
    And the AI service enhances the range validation feedback
    Then I should receive AI-enhanced validation feedback
    And the feedback should indicate financial concern
    And the feedback should reflect client anxiety about exposure levels
    And the feedback should suggest risk mitigation strategies
    And the feedback should encourage strategic reconsideration

  @ai_range_validation
  Scenario: AI-enhanced validation for unrealistic plaintiff demand
    Given I am a member of the "Mitchell Legal Team" (plaintiff)
    And I am in round 1 of the negotiation
    When I submit a settlement demand of $450000
    And the AI service enhances the range validation feedback
    Then I should receive AI-enhanced validation feedback
    And the feedback should indicate concerns about aggressive positioning
    And the feedback should suggest more strategic opening position
    And the feedback should maintain client relationship authenticity
    And the feedback should provide educational guidance on negotiation dynamics

  @ai_range_validation
  Scenario: AI-enhanced validation for conservative defendant offer
    Given I am a member of the "TechFlow Defense Team" (defendant)
    And I am in round 2 of the negotiation
    When I submit a counteroffer of $50000
    And the AI service enhances the range validation feedback
    Then I should receive AI-enhanced validation feedback
    And the feedback should indicate potential insulting nature of offer
    And the feedback should suggest good faith negotiation approaches
    And the feedback should reflect client concern about relationship damage
    And the feedback should encourage more reasonable positioning

  @ai_fallback_validation
  Scenario: Handle AI service unavailability during range validation
    Given I am a member of the "Mitchell Legal Team" (plaintiff)
    And the Google AI service is temporarily unavailable
    When I submit a settlement demand of $200000
    And the system attempts to enhance range validation with AI
    Then I should receive standard range validation feedback
    And the feedback should still be contextually appropriate
    And the validation logic should remain accurate
    And the error should be logged for monitoring
    And my user experience should not be disrupted

  @ai_contextual_validation
  Scenario: AI-enhanced validation considers negotiation context
    Given I am a member of the "Mitchell Legal Team" (plaintiff)
    And I am in round 4 of the negotiation
    And previous rounds have shown gradual movement
    When I submit a settlement demand of $225000
    And the AI service enhances validation with historical context
    Then I should receive contextually aware validation feedback
    And the feedback should acknowledge negotiation progress
    And the feedback should consider round timing pressures
    And the feedback should reflect appropriate urgency levels
    And the feedback should maintain strategic perspective

  @ai_pressure_level_validation
  Scenario: AI-enhanced pressure level assessment with personality
    Given I am a member of the "TechFlow Defense Team" (defendant)
    And my client has a risk-averse personality profile
    And I am in round 5 of the negotiation
    When I submit a counteroffer of $225000
    And the AI service enhances pressure assessment with personality factors
    Then I should receive personality-aware validation feedback
    And the feedback should reflect risk-averse client concerns
    And the feedback should include appropriate anxiety levels
    And the feedback should suggest personality-consistent strategies
    And the feedback should maintain client characterization consistency

  @ai_gap_analysis
  Scenario: AI-enhanced gap analysis for settlement potential
    Given both teams have submitted offers in round 3
    And the plaintiff offer is $250000
    And the defendant offer is $175000
    When the AI service analyzes the settlement gap
    Then I should receive AI-enhanced gap analysis
    And the analysis should identify creative bridging opportunities
    And the analysis should assess realistic settlement probability
    And the analysis should suggest non-monetary terms potential
    And the analysis should provide timeline considerations
    And the analysis should maintain educational value

  @ai_event_impact_validation
  Scenario: AI-enhanced validation after simulation events
    Given I am a member of the "Mitchell Legal Team" (plaintiff)
    And the "media attention" event has recently triggered
    And the event has adjusted acceptable ranges
    When I submit a settlement demand of $275000
    And the AI service validates offer considering event impacts
    Then I should receive event-aware validation feedback
    And the feedback should acknowledge recent developments
    And the feedback should reflect updated client confidence
    And the feedback should consider strategic timing
    And the feedback should maintain narrative consistency

  @ai_validation_consistency
  Scenario: Maintain validation consistency across AI interactions
    Given I am a member of the "TechFlow Defense Team" (defendant)
    And I have submitted previous offers with consistent client feedback
    When I submit a counteroffer of $150000
    And the AI service validates with previous interaction context
    Then I should receive consistent validation feedback
    And the feedback should build on previous client responses
    And the feedback should maintain personality continuity
    And the feedback should show logical progression
    And the feedback should reflect accumulated client trust

  @ai_validation_configuration
  Scenario: Respect AI validation configuration settings
    Given I am an instructor managing AI validation settings
    When I disable AI-enhanced range validation
    And students submit offers requiring validation
    Then AI services should not be called for validation
    And standard range validation should be used exclusively
    And no additional API costs should be incurred for validation
    And validation accuracy should remain intact
    And student experience should remain consistent

  @ai_validation_quality
  Scenario: Validate AI-enhanced range validation quality
    Given multiple students submit offers across different scenarios
    When the AI service provides enhanced validation feedback
    Then all validation feedback should be professionally appropriate
    And validation should maintain legal education focus
    And validation should avoid revealing simulation mechanics
    And validation should encourage learning objectives
    And validation should provide realistic client perspectives
    And validation should support negotiation skill development

  @ai_validation_performance
  Scenario: Monitor AI validation performance and costs
    Given the AI-enhanced range validation system is active
    When multiple teams submit offers simultaneously
    And the system tracks validation performance and costs
    Then validation response times should meet performance targets
    And API usage should be monitored against daily limits
    And cost tracking should be accurate for validation calls
    And system should gracefully handle validation quota limits
    And fallback validation should maintain service quality

  @ai_multi_round_validation
  Scenario: AI-enhanced validation across multiple negotiation rounds
    Given I am a member of the "Mitchell Legal Team" (plaintiff)
    And I have submitted offers in rounds 1, 2, and 3
    When I submit a settlement demand of $200000 in round 4
    And the AI service validates considering multi-round context
    Then I should receive context-aware validation feedback
    And the feedback should acknowledge negotiation evolution
    And the feedback should reflect strategic positioning changes
    And the feedback should consider client patience levels
    And the feedback should suggest appropriate next steps
    And the feedback should maintain educational progression