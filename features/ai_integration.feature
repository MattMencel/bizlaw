Feature: AI Integration
  As a system administrator
  I want to integrate Google AI services
  So that the platform can provide intelligent feedback and analysis

  Background:
    Given the Google AI service is configured
    And I have a legal simulation with teams

  Scenario: Generate AI-powered client feedback
    Given a settlement offer has been submitted
    When the AI service generates feedback for the offer
    Then the feedback should be contextually relevant
    And the feedback should include mood assessment
    And the feedback should provide strategic guidance

  Scenario: Generate strategic negotiation advice
    Given a negotiation is in progress
    And the current round is 3
    When the AI service analyzes the negotiation state
    Then strategic advice should be generated
    And the advice should consider both team positions
    And the advice should be appropriate for the current round

  Scenario: Handle AI service errors gracefully
    Given the Google AI service is unavailable
    When the system attempts to generate AI feedback
    Then a fallback response should be provided
    And the error should be logged
    And the user experience should not be interrupted

  Scenario: Generate contextual settlement recommendations
    Given a negotiation with a large settlement gap
    When the AI service analyzes potential settlement paths
    Then creative settlement options should be suggested
    And risk assessments should be provided
    And the recommendations should be role-specific

  Scenario: AI service respects configuration settings
    Given the Google AI service is disabled in configuration
    When the system attempts to use AI features
    Then AI services should not be called
    And fallback responses should be used
    And no API costs should be incurred

  @ai_mocking
  Scenario: Mock AI responses for testing
    Given the AI service is in mock mode
    When AI feedback is requested
    Then a predefined mock response should be returned
    And the response should match expected format
    And performance should not be impacted