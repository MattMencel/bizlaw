Feature: Course Management within Organizations
  As an instructor or admin
  I want to manage courses within my organization
  So that I can organize students, teams, and cases effectively

  Background:
    Given I am logged in as an instructor or admin
    And I belong to an organization "University of Business Law"

  Scenario: Creating a new course
    When I navigate to create a new course
    And I enter course details:
      | Field         | Value                    |
      | Title         | Advanced Business Law    |
      | Course Code   | BUS301                  |
      | Description   | Advanced legal concepts  |
      | Instructor    | Prof. Smith             |
      | Term          | Fall 2024               |
      | Max Students  | 30                      |
    And I submit the form
    Then I should see a confirmation that the course was created
    And the course should be associated with my organization
    And the course should appear in the organization's course list

  Scenario: Viewing courses in my organization
    Given the following courses exist in my organization:
      | Title                 | Course Code | Term      | Students |
      | Business Law 101      | BUS101      | Fall 2024 | 25       |
      | Advanced Business Law | BUS301      | Fall 2024 | 18       |
      | Contract Law          | BUS201      | Fall 2024 | 22       |
    When I visit the courses page
    Then I should see all courses from my organization
    And I should see course enrollment numbers
    And I should be able to filter by term

  Scenario: Enrolling students in a course
    Given I have a course "Business Law 101"
    And there are students in my organization
    When I invite students to enroll in the course
    And students accept the invitations
    Then the students should be enrolled in the course
    And the course enrollment count should increase
    And students should have access to the course materials

  Scenario: Managing teams within a course
    Given I have a course "Business Law 101" with enrolled students
    When students create teams within the course
    Then teams should only include students from that course
    And teams should be scoped to the specific course
    And I should be able to view all teams for the course

  Scenario: Creating cases for a course
    Given I have a course "Business Law 101" with teams
    When I create a new case for the course
    And I assign teams from the course to the case
    Then the case should be associated with the course
    And only teams from that course should be available for assignment
    And students should only see cases from their enrolled courses

  Scenario: Cross-course isolation
    Given I have multiple courses:
      | Course            | Students           | Teams              |
      | Business Law 101  | Alice, Bob         | Team Alpha         |
      | Advanced Law 301  | Charlie, Diana     | Team Beta          |
    When Alice views available teams
    Then she should only see "Team Alpha"
    And she should not see "Team Beta"
    When I create a case for "Business Law 101"
    Then only students from "Business Law 101" should have access

  Scenario: Term-based course organization
    Given my organization has terms:
      | Term Name   | Start Date | End Date   |
      | Fall 2024   | 2024-09-01 | 2024-12-15 |
      | Spring 2025 | 2025-01-15 | 2025-05-15 |
    When I create courses for different terms
    Then courses should be grouped by term
    And I should be able to view courses by academic year
    And term-specific enrollment should be managed appropriately