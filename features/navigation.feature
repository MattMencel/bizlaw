Feature: Hierarchical Navigation System
  As a user of the legal education platform
  I want to navigate through the application using a hierarchical menu system
  So that I can efficiently access case files, negotiations, and other features

  Background:
    Given an organization exists
    And a user "john@example.com" exists with role "student" in the organization
    And a case "Mitchell v. TechFlow Industries" exists
    And a team "Plaintiff Legal Team" exists for the case
    And the user is a member of the team

  @javascript
  Scenario: Student sees appropriate navigation sections
    Given I am signed in as "john@example.com"
    When I visit the dashboard
    Then I should see the hierarchical navigation
    And I should see the "Legal Workspace" section
    And I should see the "Case Files" section
    And I should see the "Negotiations" section
    And I should see the "Personal" section
    And I should not see the "Administration" section

  @javascript
  Scenario: Context switcher displays current case and team
    Given I am signed in as "john@example.com"
    When I visit the dashboard
    Then I should see "Mitchell v. TechFlow Industries" in the context switcher
    And I should see "Plaintiff Legal Team" in the context switcher
    And I should see the current phase information
    And I should see the team status indicator

  @javascript
  Scenario: Expanding and collapsing navigation sections
    Given I am signed in as "john@example.com"
    When I visit the dashboard
    And I click on the "Case Files" section header
    Then the "Case Files" section should collapse
    When I click on the "Case Files" section header again
    Then the "Case Files" section should expand

  @javascript
  Scenario: Context switching between cases
    Given another case "Contract Dispute - ABC Corp" exists
    And another team "Defense Team" exists for the second case
    And the user is a member of the second team
    And I am signed in as "john@example.com"
    When I visit the dashboard
    And I click on the context switcher
    Then I should see the context switcher dropdown
    And I should see "Contract Dispute - ABC Corp" as an option
    When I click on "Contract Dispute - ABC Corp"
    Then I should see "Contract Dispute - ABC Corp" in the context switcher
    And I should see "Defense Team" in the context switcher

  @javascript
  Scenario: Navigation state persistence
    Given I am signed in as "john@example.com"
    When I visit the dashboard
    And I collapse the "Case Files" section
    And I refresh the page
    Then the "Case Files" section should remain collapsed

  @javascript
  Scenario: Navigation accessibility
    Given I am signed in as "john@example.com"
    When I visit the dashboard
    And I use keyboard navigation with the Tab key
    Then I should be able to navigate through all navigation items
    When I press the Enter key on a section header
    Then the section should toggle its expanded state
    When I press the Escape key
    Then any open dropdowns should close

  @javascript
  Scenario: Instructor sees administration section
    Given a user "instructor@example.com" exists with role "instructor" in the organization
    And I am signed in as "instructor@example.com"
    When I visit the dashboard
    Then I should see the "Administration" section
    And I should see "Academic Structure" in the Administration section
    And I should see "User Management" in the Administration section

  @javascript
  Scenario: Admin sees full administration section
    Given a user "admin@example.com" exists with role "admin" in the organization
    And I am signed in as "admin@example.com"
    When I visit the dashboard
    Then I should see the "Administration" section
    And I should see "Organization" in the Administration section
    And I should see "Academic Structure" in the Administration section
    And I should see "User Management" in the Administration section
    And I should see "System Settings" in the Administration section

  @javascript
  Scenario: Mobile navigation behavior
    Given I am signed in as "john@example.com"
    When I visit the dashboard on a mobile device
    Then I should see the mobile navigation toggle
    And the main navigation should be hidden
    When I click the mobile navigation toggle
    Then the mobile navigation menu should slide out
    When I click outside the mobile menu
    Then the mobile navigation menu should close

  @javascript
  Scenario: Context switcher search functionality
    Given multiple cases exist for the user
    And I am signed in as "john@example.com"
    When I visit the dashboard
    And I click on the context switcher
    And I type "Mitchell" in the search field
    Then I should see "Mitchell v. TechFlow Industries" in the search results
    And I should not see other cases in the search results

  @javascript
  Scenario: Evidence vault navigation
    Given I am signed in as "john@example.com"
    When I visit the dashboard
    And I expand the "Case Files" section
    And I expand the "Evidence Management" subsection
    Then I should see "Document Vault" link
    And I should see "Evidence Bundles" link
    And I should see "Annotations" link
    And I should see "Document Search" link

  @javascript
  Scenario: Negotiations section navigation
    Given I am signed in as "john@example.com"
    When I visit the dashboard
    And I expand the "Negotiations" section
    Then I should see "Settlement Portal" subsection
    And I should see "Client Relations" subsection
    When I expand the "Settlement Portal" subsection
    Then I should see "Submit Offers" link
    And I should see "Offer Templates" link
    And I should see "Damage Calculator" link

  @javascript
  Scenario: Navigation item active states
    Given I am signed in as "john@example.com"
    When I visit the evidence vault page
    Then the "Document Vault" navigation item should be highlighted
    When I visit the negotiations page
    Then the "Submit Offers" navigation item should be highlighted

  @javascript
  Scenario: Role-based navigation visibility
    Given I am signed in as "john@example.com"
    When I visit the dashboard
    Then I should not see "Organization" in any navigation section
    And I should not see "System Settings" in any navigation section
    And I should not see administrative user management options

  @javascript
  Scenario: Context switcher error handling
    Given I am signed in as "john@example.com"
    When I visit the dashboard
    And I click on the context switcher
    And the context switching API is unavailable
    Then I should see an error message
    And the context switcher should remain functional

  @javascript
  Scenario: Navigation performance with many cases
    Given the user has access to 20 cases
    And I am signed in as "john@example.com"
    When I visit the dashboard
    And I click on the context switcher
    Then the dropdown should load within 2 seconds
    And I should see pagination or limited results

  @javascript
  Scenario: Deep navigation structure
    Given I am signed in as "john@example.com"
    When I visit the dashboard
    And I expand all navigation sections
    Then I should see proper indentation for subsections
    And I should see appropriate spacing between sections
    And the navigation should remain scrollable if needed