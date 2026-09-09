Feature: A Consult buys the one read a Team gets on its own Client
  Consulting is the only way a Team learns how far its Client has moved, and
  what it buys is qualitative — a band, in the Client's own words, and never a
  number. It yields no paper, so the Docket line is the only other place the
  band can land, and the line is on the record forever: a Team that consults on
  one Day and re-reads the line later reads what the Client said then. A band
  that moves is shown at the next Consult, not the moment it moves.

  Background:
    Given the reference Case has been imported
    And a Section at Western Illinois University
    And the Instructor creates a Simulation of the reference Case
    And Dana is on the plaintiff Side

  Scenario: A Consult costs a point of preparation and hands back a band, not paper
    When Dana consults her Client on Day 1
    Then her Client is firm
    And the plaintiff Side has 7 preparation points left on Day 1
    And the plaintiff Case File holds nothing it did not start with
    And the Consult is on the plaintiff Docket, and the line says firm
    And her Client's face is drawn from the band

  Scenario: The Client moves, and the line already bought does not
    Given Dana consults her Client on Day 1
    When the plaintiff Client is moved most of the way through their bound
    Then the Consult Dana already bought still reads firm
    When Dana consults her Client on Day 1
    Then her Client is ready
    And the two Consults are answered in different words

  Scenario: A band keeps its own count, so a Client moving does not skip a line
    Given Dana consults her Client on Day 1
    When the plaintiff Client is moved most of the way through their bound
    And Dana consults her Client on Day 1
    And Dana consults her Client on Day 1
    Then the ready Client answered with its own two variants, in order
