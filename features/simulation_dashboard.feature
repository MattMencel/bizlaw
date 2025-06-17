# Legal Simulation Dashboard - Student Homepage

@simulation_dashboard
Feature: Simulation Dashboard Homepage
  As a student user
  I want to see a comprehensive dashboard of my simulation activities
  So that I can easily track my progress and access my current simulations

  Background:
    Given the system has the following users:
      | email                    | role       | first_name | last_name |
      | student@example.com      | student    | John       | Doe       |
      | instructor@example.com   | instructor | Jane       | Smith     |
    And I am logged in as "student@example.com"
    And I am a member of team "Plaintiff Team A"
    And I am a member of team "Defense Team B"

  @dashboard_overview
  Scenario: View simulation dashboard with active simulations
    Given I have an active simulation "Mitchell v. TechFlow Industries" as plaintiff
    And I have a completed simulation "Johnson v. MegaCorp" as defendant  
    And I have a pending simulation "Wilson v. StartupX" as plaintiff
    When I visit the simulation dashboard homepage
    Then I should see the page title "Simulation Dashboard"
    And I should see a "My Active Simulations" section
    And I should see "Mitchell v. TechFlow Industries" in the active simulations
    And I should see a "Recent Activity" section
    And I should see a "Simulation Stats" section with my completion metrics
    And I should see quick action buttons for "Join Simulation" and "View Case Materials"

  @empty_dashboard  
  Scenario: View dashboard with no simulations
    Given I have no simulations assigned
    When I visit the simulation dashboard homepage
    Then I should see the page title "Simulation Dashboard"
    And I should see "No active simulations" in the active simulations section
    And I should see "Get started by joining a simulation or waiting for assignment"
    And I should see an empty state illustration
    And I should see a "Browse Available Simulations" button

  @simulation_status_cards
  Scenario: View detailed simulation status information
    Given I have an active simulation "Mitchell v. TechFlow Industries" with the following details:
      | case_type              | sexual_harassment |
      | current_round          | 3                 |
      | total_rounds           | 6                 |
      | my_team_role           | plaintiff         |
      | last_offer_amount      | 275000            |
      | negotiation_deadline   | tomorrow          |
    When I visit the simulation dashboard homepage
    Then I should see the simulation card for "Mitchell v. TechFlow Industries"
    And I should see "Round 3 of 6" in the simulation status
    And I should see "Plaintiff Team" as my role
    And I should see "Last Offer: $275,000" 
    And I should see "Deadline: Tomorrow" with urgent styling
    And I should see a "Continue Negotiation" button

  @quick_actions
  Scenario: Access quick actions from dashboard
    Given I have an active simulation "Mitchell v. TechFlow Industries"
    When I visit the simulation dashboard homepage
    And I click "Continue Negotiation" for "Mitchell v. TechFlow Industries"
    Then I should be redirected to the negotiation interface for that simulation
    
  @stats_overview
  Scenario: View personal simulation statistics
    Given I have completed 2 simulations with settlements
    And I have completed 1 simulation that went to arbitration
    And I have 1 active simulation
    When I visit the simulation dashboard homepage
    Then I should see my stats overview containing:
      | stat_name                | value |
      | Active Simulations       | 1     |
      | Completed Simulations    | 3     |
      | Settlement Success Rate  | 67%   |
      | Average Completion Time  | 4.5 days |

  @recent_activity
  Scenario: View recent simulation activity feed
    Given I have recent simulation activities:
      | activity_type        | simulation_name              | time_ago    | description                           |
      | offer_submitted      | Mitchell v. TechFlow         | 2 hours ago | Submitted counteroffer of $275,000    |
      | event_triggered      | Mitchell v. TechFlow         | 1 day ago   | Media attention event activated       |
      | simulation_completed | Johnson v. MegaCorp          | 3 days ago  | Simulation completed with settlement  |
    When I visit the simulation dashboard homepage
    Then I should see my recent activities listed chronologically
    And I should see "Submitted counteroffer of $275,000" from 2 hours ago
    And I should see "Media attention event activated" from 1 day ago
    And I should see "Simulation completed with settlement" from 3 days ago

  @team_notifications
  Scenario: View team-based notifications and alerts
    Given my team "Plaintiff Team A" has pending actions:
      | notification_type | message                                    | urgency |
      | deadline_reminder | Negotiation deadline in 6 hours           | high    |
      | team_message      | New strategy document uploaded by teammate | medium  |
      | event_alert       | Court scheduling pressure event triggered  | medium  |
    When I visit the simulation dashboard homepage
    Then I should see a "Team Notifications" section
    And I should see the urgent deadline reminder highlighted in red
    And I should see notification indicators showing unread count
    And I should be able to dismiss individual notifications

  @responsive_layout
  Scenario: Dashboard works on mobile devices
    Given I have an active simulation "Mitchell v. TechFlow Industries"
    When I visit the simulation dashboard homepage on a mobile device
    Then the layout should be responsive and mobile-friendly
    And simulation cards should stack vertically
    And quick action buttons should be easily tappable
    And navigation should use a collapsible menu

  @role_based_content
  Scenario: Dashboard shows role-appropriate content for students
    Given I am logged in as a student
    When I visit the simulation dashboard homepage
    Then I should see student-specific navigation options
    And I should see "My Simulations" instead of "All Simulations"
    And I should not see instructor-only features like "Create Simulation"
    And I should see learning resources appropriate for my level

  @loading_states
  Scenario: Dashboard handles loading and error states gracefully
    Given the simulation data is slow to load
    When I visit the simulation dashboard homepage
    Then I should see loading indicators for each dashboard section
    And I should see skeleton placeholders for simulation cards
    When the data loads successfully
    Then the loading indicators should be replaced with actual content
    And the interface should be fully interactive