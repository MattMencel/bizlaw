Feature: Health Check
  In order to monitor the application's health
  As a system administrator
  I want to check the application's status

  Scenario: Getting health status
    When I make a GET request to "/health"
    Then the response status should be 200
    And the response should include "status" with value "ok"
    And the response should include a "timestamp"
