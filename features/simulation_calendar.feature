Feature: A Simulation arrives with its calendar already laid out
  An Instructor starts a Simulation from a published Case Version, and the whole
  run's calendar exists before Day 1 is played — so an Action taken today can
  name the Day its result lands on, and the schedule can be previewed.

  Background:
    Given the reference Case has been imported
    And a Section at Western Illinois University

  Scenario: The Days of the reference Case are read back in order
    When the Instructor creates a Simulation of the reference Case
    Then the Simulation has 10 Days
    And the Days run in order from 2026-03-02 to 2026-03-13
    And every Day is open

  Scenario: The Simulation has the two Sides of the dispute
    When the Instructor creates a Simulation of the reference Case
    Then the Simulation has a plaintiff Side and a defendant Side

  Scenario: A draft Case Version cannot be pinned
    Given the reference Case also has a draft version
    When the Instructor tries to create a Simulation of the draft version
    Then the Simulation is refused
