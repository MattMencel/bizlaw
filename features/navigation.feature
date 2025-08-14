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
    And I should see "Admin Dashboard" in the Administration section
    And I should see "License Management" in the Administration section

  @javascript
  Scenario: Admin navigation links are functional
    Given a user "admin@example.com" exists with role "admin" in the organization
    And I am signed in as "admin@example.com"
    When I visit the dashboard
    And I click on "Organization" in the Administration section
    Then I should be redirected to the organizations management page
    When I click on "System Settings" in the Administration section
    Then I should be redirected to the admin settings page
    When I click on "Admin Dashboard" in the Administration section
    Then I should be redirected to the admin dashboard page
    When I click on "License Management" in the Administration section
    Then I should be redirected to the license management page

  @javascript
  Scenario: Mobile navigation behavior
    Given I am signed in as "john@example.com"
    When I visit the dashboard on a mobile device
    Then I should see the mobile navigation toggle
    And the main navigation should be hidden
    When I click the mobile navigation toggle
    Then the mobile navigation menu should slide out
    And the navigation should not occupy more than 100% of the screen width
    When I click outside the mobile menu
    Then the mobile navigation menu should close

  @javascript
  Scenario: Mobile navigation responsiveness
    Given I am signed in as "john@example.com"
    When I visit the dashboard
    And I resize the browser to mobile width (375px)
    Then the navigation should automatically switch to mobile mode
    And the hamburger menu should be visible
    And the main content should be fully accessible
    When I resize back to desktop width
    Then the navigation should return to desktop mode
    And the hamburger menu should be hidden

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

  @javascript
  Scenario: Navigation URLs resolve to current case for students
    Given I am signed in as "john@example.com"
    When I visit the dashboard
    And I expand the "Case Files" section
    And I expand the "Evidence Management" subsection
    Then the "Document Vault" link should contain the current case ID
    And the "Evidence Bundles" link should contain the current case ID
    And the "Document Vault" link should not contain "current"
    And the "Evidence Bundles" link should not contain "current"

  @javascript
  Scenario: Navigation URLs show fallbacks for users without active cases
    Given a user "instructor@example.com" exists with role "instructor" in the organization
    And I am signed in as "instructor@example.com"
    When I visit the dashboard
    And I expand the "Case Files" section
    And I expand the "Evidence Management" subsection
    Then the "Document Vault" link should have href "#"
    And the "Evidence Bundles" link should have href "#"
    When I expand the "Negotiations" section
    And I expand the "Settlement Portal" subsection
    Then the "Submit Offers" link should have href "#"
    And the "Offer Templates" link should have href "#"
    And the "Damage Calculator" link should have href "#"

  @javascript
  Scenario: Negotiation URLs resolve to current case for students
    Given I am signed in as "john@example.com"
    When I visit the dashboard
    And I expand the "Negotiations" section
    And I expand the "Settlement Portal" subsection
    Then the "Submit Offers" link should contain the current case ID
    And the "Offer Templates" link should contain the current case ID
    And the "Damage Calculator" link should contain the current case ID
    And the "Submit Offers" link should not contain "current"
    And the "Offer Templates" link should not contain "current"
    And the "Damage Calculator" link should not contain "current"

  @javascript
  Scenario: Case context switching updates navigation URLs
    Given another case "Contract Dispute - ABC Corp" exists
    And another team "Defense Team" exists for the second case
    And the user is a member of the second team
    And I am signed in as "john@example.com"
    When I visit the dashboard
    And I expand the "Case Files" section
    And I expand the "Evidence Management" subsection
    Then the "Document Vault" link should contain the current case ID
    When I click on the context switcher
    And I click on "Contract Dispute - ABC Corp"
    Then the "Document Vault" link should contain the second case ID
    And the "Document Vault" link should not contain the first case ID

  @javascript
  Scenario: Safe navigation fallbacks prevent broken links
    Given a user "instructor@example.com" exists with role "instructor" in the organization
    And I am signed in as "instructor@example.com"
    When I visit the dashboard
    And I expand the "Case Files" section
    And I expand the "Evidence Management" subsection
    And I click on the "Document Vault" link
    Then I should remain on the dashboard page
    And I should not see any error messages
    And the page should remain functional

  @javascript
  Scenario: Context switcher shows appropriate state for different user types
    Given I am signed in as "john@example.com"
    When I visit the dashboard
    Then the context switcher should show "Mitchell v. TechFlow Industries"
    And the context switcher should show "Plaintiff Legal Team"
    And the context switcher should show "Student"
    When I sign out
    And a user "instructor@example.com" exists with role "instructor" in the organization
    And I am signed in as "instructor@example.com"
    And I visit the dashboard
    Then the context switcher should show "Select a Case"
    And the context switcher should show "No Team"
    And the context switcher should show "Instructor"

  @javascript
  Scenario: Evidence vault links work correctly for students with cases
    Given I am signed in as "john@example.com"
    When I visit the dashboard
    And I expand the "Case Files" section
    And I expand the "Evidence Management" subsection
    And I click on the "Document Vault" link
    Then I should be navigated to the evidence vault page for the current case
    And the URL should contain the case ID
    And the URL should not contain "current"

  @javascript
  Scenario: Navigation maintains accessibility with case context
    Given I am signed in as "john@example.com"
    When I visit the dashboard
    And I expand the "Case Files" section
    And I expand the "Evidence Management" subsection
    Then the "Document Vault" link should have proper aria attributes
    And the "Evidence Bundles" link should have proper aria attributes
    When I use keyboard navigation to reach the "Document Vault" link
    And I press Enter
    Then I should be navigated to the evidence vault page

  @javascript
  Scenario: Multiple case users see correct URLs after case switching
    Given another case "Contract Dispute - ABC Corp" exists
    And another team "Defense Team" exists for the second case
    And the user is a member of the second team
    And I am signed in as "john@example.com"
    When I visit the dashboard
    And I expand the "Negotiations" section
    And I expand the "Settlement Portal" subsection
    And I note the current "Submit Offers" link URL
    When I click on the context switcher
    And I click on "Contract Dispute - ABC Corp"
    And I wait for the context to switch
    Then the "Submit Offers" link URL should be different from the noted URL
    And the "Submit Offers" link should contain the second case ID
