# Evidence Release System - Strategic Evidence Management for Legal Simulations

@evidence_releases
Feature: Evidence Release System
  As a participant in legal case simulations
  I want to strategically manage evidence disclosure and requests
  So that I can create dynamic and realistic legal proceedings

  Background:
    Given the system has the following users:
      | email                    | role       | first_name | last_name |
      | student1@example.com     | student    | Alice      | Johnson   |
      | student2@example.com     | student    | Bob        | Smith     |
      | student3@example.com     | student    | Carol      | Davis     |
      | instructor@example.com   | instructor | Dr.        | Williams  |
    And I have the following teams:
      | name               | type      |
      | Plaintiff Team A   | plaintiff |
      | Defense Team B     | defendant |
    And the teams have the following members:
      | team_name          | user_email           | role    |
      | Plaintiff Team A   | student1@example.com | member  |
      | Plaintiff Team A   | student2@example.com | leader  |
      | Defense Team B     | student3@example.com | member  |
    And I have a case "Mitchell v. TechFlow Industries" with active simulation
    And the simulation is in round 1 of 4 rounds
    And the case has the following evidence documents:
      | title                           | evidence_type        | access_level     | case_material |
      | HR Investigation Report         | company_document     | case_teams       | true          |
      | Expert Damages Assessment       | expert_report        | instructor_only  | true          |
      | Security Camera Footage         | surveillance_footage | instructor_only  | true          |
      | Employee Performance Reviews    | performance_review   | instructor_only  | true          |
      | Company Financial Records       | financial_document   | instructor_only  | true          |

  @automatic_releases
  Scenario: Instructor schedules automatic evidence releases
    Given I am logged in as "instructor@example.com"
    And I am viewing the evidence release schedule for "Mitchell v. TechFlow Industries"
    When I schedule the following automatic releases:
      | document_title                | evidence_type        | release_round | impact_description                    |
      | Expert Damages Assessment     | expert_report        | 2             | Critical expert analysis on damages   |
      | Security Camera Footage       | surveillance_footage | 3             | Key surveillance evidence             |
      | Company Financial Records     | financial_document   | 4             | Financial impact documentation        |
    Then I should see "3 evidence releases scheduled successfully"
    And I should see the releases scheduled for the appropriate rounds
    And I should see calculated release dates based on simulation timeline
    And the documents should remain instructor-only until release

  @team_evidence_requests
  Scenario: Students request early evidence release
    Given I am logged in as "student2@example.com"
    And I am a member of "Plaintiff Team A"
    And there are scheduled evidence releases for rounds 2-4
    When I visit the evidence vault for "Mitchell v. TechFlow Industries"
    And I click "Request Additional Evidence"
    And I select "Expert Damages Assessment" from the available documents
    And I select evidence type "expert_report"
    And I provide justification "We need the expert analysis to prepare our damages argument"
    And I click "Submit Evidence Request"
    Then I should see "Evidence request submitted successfully"
    And I should see "Pending instructor approval" in my team's requests
    And the instructor should receive a notification about the pending request

  @instructor_approval_workflow
  Scenario: Instructor reviews and approves evidence requests
    Given I am logged in as "instructor@example.com"
    And "Plaintiff Team A" has requested "Expert Damages Assessment"
    And the request justification is "We need expert analysis for damages calculation"
    When I visit the evidence release management page
    Then I should see "1 pending evidence request"
    When I click on the pending request from "Plaintiff Team A"
    Then I should see the team's justification
    And I should see the document details
    And I should see impact analysis
    When I click "Approve Request"
    And I add approval note "Request meets case requirements"
    And I confirm the approval
    Then I should see "Evidence request approved"
    And the document should become available to "Plaintiff Team A"
    And "Plaintiff Team A" should receive approval notification
    And a case event should be recorded

  @instructor_denial_workflow
  Scenario: Instructor denies evidence request
    Given I am logged in as "instructor@example.com"
    And "Defense Team B" has requested "Company Financial Records"
    When I visit the evidence release management page
    And I click on the pending request from "Defense Team B"
    And I click "Deny Request"
    And I provide denial reason "Financial records not relevant at this stage"
    And I confirm the denial
    Then I should see "Evidence request denied"
    And the document should remain instructor-only
    And "Defense Team B" should receive denial notification with reason
    And the team should be able to submit a revised request

  @evidence_release_timeline
  Scenario: Evidence releases according to simulation rounds
    Given I am logged in as "instructor@example.com"
    And I have scheduled evidence releases for each round
    And the simulation starts on "2024-01-15"
    When round 2 begins on "2024-01-22"
    Then "Expert Damages Assessment" should be automatically released
    And both teams should have access to the document
    And a simulation event should be created
    When round 3 begins on "2024-01-29"
    Then "Security Camera Footage" should be automatically released
    And I should see the release reflected in the evidence vault
    And teams should receive notifications about new evidence

  @evidence_impact_on_simulation
  Scenario: Evidence releases affect simulation dynamics
    Given I am logged in as "student1@example.com"
    And I am a member of "Plaintiff Team A"
    And "Expert Damages Assessment" has been released in round 2
    When I visit the evidence vault
    Then I should see "Expert Damages Assessment" marked as "Recently Released"
    And I should see the impact description
    When I view the case dashboard
    Then I should see updated case pressure indicators
    And I should see notification about strategic implications
    And I should be able to access the new evidence for case preparation

  @team_evidence_strategy
  Scenario: Teams manage evidence requests strategically
    Given I am logged in as "student2@example.com"
    And I am a leader of "Plaintiff Team A"
    When I visit our team's evidence strategy page
    Then I should see our pending evidence requests
    And I should see approved evidence with access dates
    And I should see denied requests with reasons
    And I should see remaining evidence request quota for this round
    When I click "Request Strategy Meeting"
    Then I should be able to schedule team discussion about evidence needs

  @cross_team_evidence_visibility
  Scenario: Evidence visibility respects team boundaries
    Given I am logged in as "student1@example.com"
    And I am a member of "Plaintiff Team A"
    And "Defense Team B" has requested "Company Financial Records"
    When I visit the evidence releases page
    Then I should see my team's evidence requests
    And I should see automatically scheduled releases
    But I should not see "Defense Team B" specific requests
    And I should not see other teams' request justifications
    When "Defense Team B" evidence is approved
    Then I should see the evidence becomes available to all teams
    But I should not see the approval details specific to their request

  @evidence_release_notifications
  Scenario: Stakeholders receive appropriate notifications
    Given the simulation has evidence scheduled for release
    When "Expert Damages Assessment" is automatically released in round 2
    Then all team members should receive email notifications
    And the notification should include:
      | information_type    | details                                    |
      | evidence_title      | Expert Damages Assessment                  |
      | evidence_type       | expert_report                              |
      | release_round       | 2                                          |
      | impact_description  | Critical expert analysis on damages       |
      | access_instructions | Available now in Evidence Vault           |
    When I log in as any team member
    Then I should see the notification in my dashboard
    And the evidence should be highlighted as "New" in the vault

  @evidence_audit_trail
  Scenario: Complete audit trail for evidence management
    Given I am logged in as "instructor@example.com"
    When I visit the case audit trail
    Then I should see all evidence-related events:
      | event_type          | description                                |
      | evidence_scheduled  | Automatic releases scheduled              |
      | evidence_requested  | Team requests for early access            |
      | evidence_approved   | Instructor approvals with reasons         |
      | evidence_denied     | Instructor denials with reasons           |
      | evidence_released   | Actual evidence releases to teams         |
    And each event should include timestamp, user, and impact details
    And I should be able to filter events by team or evidence type
    And I should be able to export the audit trail for assessment

  @evidence_mobile_access
  Scenario: Evidence management works on mobile devices
    Given I am using a mobile device
    And I am logged in as "student1@example.com"
    When I visit the evidence vault on mobile
    Then the interface should be mobile-optimized
    And I should be able to request evidence via mobile form
    And I should receive push notifications for evidence releases
    When new evidence is released
    Then I should see mobile-friendly evidence previews
    And I should be able to download evidence for offline review

  @evidence_performance_optimization
  Scenario: Evidence system handles large volumes efficiently
    Given the case has 50+ evidence documents
    And multiple teams are actively requesting evidence
    When I visit the evidence vault
    Then the page should load within 3 seconds
    And evidence filtering should be responsive
    When I search for specific evidence types
    Then results should appear instantly
    And the system should handle concurrent evidence requests without delays

  @evidence_security_compliance
  Scenario: Evidence access maintains security controls
    Given evidence documents contain sensitive information
    When any user accesses evidence
    Then all access should be logged with user identification
    And document access should respect team boundaries
    And instructor-only evidence should remain secure until release
    When evidence is downloaded
    Then download events should be tracked
    And unauthorized access attempts should be blocked and logged
