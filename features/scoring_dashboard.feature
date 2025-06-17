# Real-time Scoring Dashboard - Performance Tracking

@scoring_dashboard
Feature: Real-time Scoring Dashboard
  As a student or instructor
  I want to view real-time performance scores and analytics
  So that I can track progress and identify areas for improvement

  Background:
    Given the system has the following users:
      | email                    | role       | first_name | last_name |
      | student1@example.com     | student    | John       | Doe       |
      | student2@example.com     | student    | Jane       | Smith     |
      | instructor@example.com   | instructor | Dr. Emily  | Johnson   |
    And I belong to an organization "University of Business Law"
    And there is a course "Advanced Business Law" in my organization
    And the system has a sexual harassment case "Mitchell v. TechFlow Industries" in this course
    And the case has plaintiff team "Mitchell Legal Team" with student "student1@example.com"
    And the case has defendant team "TechFlow Defense Team" with student "student2@example.com"
    And both teams have been assigned to the case
    And the simulation is in progress with round 3 of 6 completed

  @individual_scoring_dashboard
  Scenario: Student views their individual performance dashboard
    Given I am logged in as "student1@example.com"
    And I have the following performance scores for the simulation:
      | metric                    | score | max_points |
      | settlement_quality_score  | 32    | 40         |
      | legal_strategy_score      | 24    | 30         |
      | collaboration_score       | 16    | 20         |
      | efficiency_score          | 8     | 10         |
      | speed_bonus              | 5     | 10         |
      | creative_terms_score     | 3     | 10         |
    And my total score is 88 out of 100
    When I navigate to my scoring dashboard
    Then I should see the page title "Performance Dashboard"
    And I should see my current total score "88/100" prominently displayed
    And I should see my performance grade "B" with appropriate styling
    And I should see a breakdown chart showing all score components
    And I should see "Settlement Quality: 32/40 (80%)" 
    And I should see "Legal Strategy: 24/30 (80%)"
    And I should see "Team Collaboration: 16/20 (80%)"
    And I should see "Process Efficiency: 8/10 (80%)"
    And I should see "Speed Bonus: 5/10 (50%)"
    And I should see "Creative Terms: 3/10 (30%)"

  @team_scoring_dashboard
  Scenario: Student views team performance comparison
    Given I am logged in as "student1@example.com"
    And my team "Mitchell Legal Team" has a team score of 85 out of 100
    And the opposing team "TechFlow Defense Team" has a team score of 78 out of 100
    And there are 8 other teams in the simulation with scores ranging from 65-92
    When I navigate to my scoring dashboard
    And I click on the "Team Performance" tab
    Then I should see my team's total score "85/100" highlighted
    And I should see my team's rank "3rd out of 10 teams"
    And I should see my team's percentile "70th percentile"
    And I should see a team comparison chart
    And I should see my individual contribution within the team
    And I should not see other teams' detailed breakdowns (only totals)

  @real_time_updates
  Scenario: Scores update in real-time during simulation
    Given I am logged in as "student1@example.com"
    And I am viewing my scoring dashboard
    And my current total score is 75
    When a teammate submits a high-quality settlement offer
    And the system processes the new collaboration metrics
    Then I should see my collaboration score increase without page refresh
    And I should see my total score update to reflect the new collaboration points
    And I should see a brief animation indicating the score change
    And I should see a notification "Score updated: +3 collaboration points"

  @performance_trends
  Scenario: View performance trends over time
    Given I am logged in as "student1@example.com"
    And I have score history over 6 simulation rounds:
      | round | total_score | settlement_score | strategy_score | collaboration_score |
      | 1     | 65          | 20               | 18             | 12                  |
      | 2     | 71          | 24               | 20             | 14                  |
      | 3     | 78          | 28               | 22             | 16                  |
      | 4     | 82          | 30               | 24             | 16                  |
      | 5     | 85          | 32               | 24             | 17                  |
      | 6     | 88          | 32               | 26             | 18                  |
    When I navigate to my scoring dashboard
    And I click on the "Trends" tab
    Then I should see a line chart showing my score progression over rounds
    And I should see my total score trend line from 65 to 88
    And I should see separate trend lines for each score component
    And I should see improvement indicators for each metric
    And I should see "Consistent improvement across all metrics" insight

  @strengths_and_improvements
  Scenario: View personalized strengths and improvement areas
    Given I am logged in as "student1@example.com"
    And I have the following performance scores:
      | metric                    | score | max_points |
      | settlement_quality_score  | 35    | 40         |
      | legal_strategy_score      | 28    | 30         |
      | collaboration_score       | 12    | 20         |
      | efficiency_score          | 5     | 10         |
    When I navigate to my scoring dashboard
    And I click on the "Analysis" tab
    Then I should see a "Strengths" section containing:
      | strength            |
      | Settlement Strategy |
      | Legal Reasoning     |
    And I should see an "Areas for Improvement" section containing:
      | improvement_area    |
      | Team Collaboration  |
      | Process Efficiency  |
    And I should see specific recommendations for each improvement area
    And I should see "Focus on active participation in team discussions" for collaboration
    And I should see "Streamline your research and decision-making process" for efficiency

  @bonus_points_tracking
  Scenario: Track bonus points and achievements
    Given I am logged in as "student1@example.com"
    And I have earned the following bonus points:
      | bonus_type           | points | description                           |
      | early_settlement     | 5      | Reached settlement 2 rounds early    |
      | creative_solution    | 3      | Proposed innovative non-monetary terms |
      | legal_research       | 2      | Cited relevant case precedent         |
    When I navigate to my scoring dashboard
    And I click on the "Bonus Points" tab
    Then I should see "Total Bonus Points: 10" prominently displayed
    And I should see a list of earned bonuses with descriptions
    And I should see "Early Settlement (+5): Reached settlement 2 rounds early"
    And I should see "Creative Solution (+3): Proposed innovative non-monetary terms"
    And I should see "Legal Research (+2): Cited relevant case precedent"
    And I should see available bonus opportunities I haven't earned yet
    And I should see progress bars for "Team Leadership" and "Strategic Thinking" bonuses

  @instructor_monitoring_view
  Scenario: Instructor views all students' performance dashboard
    Given I am logged in as "instructor@example.com"
    And my course has 20 students across 10 teams
    And all students have performance scores recorded
    When I navigate to the instructor scoring dashboard
    Then I should see "Class Performance Overview" as the page title
    And I should see a summary showing:
      | metric                  | value    |
      | Average Class Score     | 76.5/100 |
      | Top Performer           | 94/100   |
      | Students Needing Help   | 3        |
      | Teams at Risk           | 1        |
    And I should see a sortable table of all student scores
    And I should be able to filter by team, score range, or improvement areas
    And I should see students with scores below 60 highlighted in red
    And I should see quick action buttons to "Message Student" or "Schedule Meeting"

  @comparative_analytics
  Scenario: View class-wide performance analytics
    Given I am logged in as "instructor@example.com"
    And my class has completed the simulation
    And performance data is available for all students
    When I navigate to the instructor scoring dashboard
    And I click on the "Analytics" tab
    Then I should see a class performance distribution chart
    And I should see average scores by metric:
      | metric              | class_average |
      | Settlement Quality  | 28.5/40       |
      | Legal Strategy      | 22.1/30       |
      | Team Collaboration  | 15.8/20       |
      | Process Efficiency  | 7.2/10        |
    And I should see comparative analysis between plaintiff and defendant teams
    And I should see insights like "Defendant teams showed stronger legal strategy skills"
    And I should see recommendations for curriculum adjustments

  @mobile_responsive_scoring
  Scenario: Scoring dashboard works on mobile devices
    Given I am logged in as "student1@example.com"
    When I navigate to my scoring dashboard on a mobile device
    Then the layout should be responsive and mobile-friendly
    And score cards should stack vertically
    And charts should be touch-interactive and zoomable
    And navigation tabs should be easily tappable
    And all score details should be readable without horizontal scrolling

  @score_export_functionality
  Scenario: Export performance data for academic records
    Given I am logged in as "student1@example.com"
    And I have completed performance scores for the simulation
    When I navigate to my scoring dashboard
    And I click the "Export Report" button
    Then I should be able to download a PDF report containing:
      | section                    |
      | Overall performance summary |
      | Detailed score breakdown   |
      | Performance trends chart   |
      | Strengths and improvements |
      | Bonus points earned        |
      | Recommendations for growth |
    And the PDF should be formatted for academic portfolio inclusion
    And the PDF should include my name, course, and simulation details

  @accessibility_features
  Scenario: Scoring dashboard is accessible to users with disabilities
    Given I am logged in as "student1@example.com"
    When I navigate to my scoring dashboard using a screen reader
    Then all score values should have descriptive aria-labels
    And charts should have text alternatives describing the data
    And color-coded elements should have text or pattern indicators
    And keyboard navigation should work for all interactive elements
    And focus indicators should be clearly visible
    And the page should meet WCAG 2.1 AA accessibility standards