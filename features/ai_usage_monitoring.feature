Feature: AI Usage Monitoring and Controls
  As a system administrator
  I want to monitor and control AI API usage
  So that costs remain within budget and service remains reliable

  Background:
    Given I am logged in as an admin
    And AI services are enabled

  Scenario: API usage is tracked for each request
    When a client feedback is generated using AI
    Then the API request should be logged
    And the request count should be incremented
    And the response time should be recorded
    And the cost should be calculated and tracked

  Scenario: Daily usage monitoring
    Given there have been multiple AI requests today
    When I view the usage dashboard
    Then I should see the total requests for today
    And I should see the total cost for today
    And I should see the average response time

  Scenario: Rate limiting prevents excessive usage
    Given the rate limit is set to 100 requests per hour
    When I make 101 requests within an hour
    Then the 101st request should be queued
    And I should receive a rate limiting message
    And the request should be processed after the rate limit resets

  Scenario: Budget alerts are triggered
    Given the daily budget limit is $5.00
    When the daily usage reaches $4.50
    Then an alert should be sent to administrators
    And the alert should include current usage statistics

  Scenario: Automatic service disable at budget limit
    Given the daily budget limit is $5.00
    When the daily usage reaches $5.00
    Then AI services should be automatically disabled
    And client feedback should fall back to rule-based responses
    And administrators should be notified

  Scenario: Usage analytics over time
    Given there is usage data for the past 30 days
    When I view the analytics dashboard
    Then I should see usage trends over time
    And I should see cost trends over time
    And I should see peak usage periods

  Scenario: Request queuing during high load
    Given there are 50 concurrent AI requests
    When additional requests come in
    Then excess requests should be queued
    And requests should be processed in order
    And users should see appropriate wait messages