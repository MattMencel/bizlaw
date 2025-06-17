# Evidence Vault Interface - Legal Case Materials Management

@evidence_vault
Feature: Evidence Vault Interface
  As a student team member
  I want to efficiently search, organize, and collaborate on case materials
  So that I can build strong legal arguments and strategies

  Background:
    Given the system has the following users:
      | email                    | role       | first_name | last_name |
      | student1@example.com     | student    | Alice      | Johnson   |
      | student2@example.com     | student    | Bob        | Smith     |
      | instructor@example.com   | instructor | Dr.        | Williams  |
    And I am logged in as "student1@example.com"
    And I am a member of team "Plaintiff Team A"
    And my team is assigned to case "Mitchell v. TechFlow Industries"
    And the case has the following documents:
      | title                           | category           | access_level   | tags                            |
      | Employee Handbook               | company_policies   | case_teams     | harassment, policy              |
      | Sarah Mitchell's Email Chain    | communications     | case_teams     | evidence, email, harassment     |
      | HR Investigation Report         | evidence_documents | case_teams     | investigation, hr, findings     |
      | Expert Damages Assessment       | expert_reports     | team_restricted| damages, economics, expert      |
      | Mitchell Performance Reviews    | evidence_documents | case_teams     | performance, reviews, retaliation|
      | Security Camera Metadata        | evidence_documents | case_teams     | evidence, security, timeline    |
      | TechFlow Financial Records      | financial_records  | instructor_only| financials, confidential        |

  @document_library
  Scenario: View evidence vault document library
    When I visit the evidence vault for my case
    Then I should see the page title "Evidence Vault - Mitchell v. TechFlow Industries"
    And I should see a searchable document library
    And I should see documents organized by category
    And I should see "Employee Handbook" in the company policies section
    And I should see "Sarah Mitchell's Email Chain" in the communications section
    And I should see "HR Investigation Report" in the evidence documents section
    And I should not see "TechFlow Financial Records" as it's instructor only

  @search_functionality
  Scenario: Search documents with keywords
    Given I am viewing the evidence vault
    When I search for "harassment"
    Then I should see search results containing:
      | document_title                  | highlight_reason                |
      | Employee Handbook               | Tagged with harassment          |
      | Sarah Mitchell's Email Chain    | Tagged with harassment          |
    And I should not see "TechFlow Financial Records"
    And I should see search term "harassment" highlighted in results

  @advanced_filtering
  Scenario: Filter documents by category and tags
    Given I am viewing the evidence vault
    When I filter by category "evidence_documents"
    Then I should see only documents in the evidence documents category:
      | document_title                  |
      | HR Investigation Report         |
      | Mitchell Performance Reviews    |
      | Security Camera Metadata        |
    When I further filter by tag "timeline"
    Then I should see only "Security Camera Metadata"

  @document_preview
  Scenario: Preview document without leaving vault
    Given I am viewing the evidence vault
    When I click on "Employee Handbook" to preview
    Then I should see a document preview modal
    And I should see the document title "Employee Handbook"
    And I should see document metadata including category and tags
    And I should see "Download" and "Annotate" action buttons
    And I should be able to close the preview and return to the vault

  @collaborative_annotations
  Scenario: Add and view team annotations on documents
    Given I am viewing the evidence vault
    And "HR Investigation Report" has existing annotations from my teammate
    When I open "HR Investigation Report" for annotation
    Then I should see existing annotations from "Bob Smith"
    When I add an annotation "This contradicts the employee handbook policy on page 15"
    And I save my annotation
    Then I should see my annotation marked with "Alice Johnson"
    And my annotation should be visible to other team members
    And I should see an annotation indicator on the document in the vault

  @evidence_organization
  Scenario: Organize evidence by strength and relevance
    Given I am viewing the evidence vault
    When I view the evidence organization panel
    Then I should see documents grouped by:
      | evidence_strength | documents                               |
      | High              | Sarah Mitchell's Email Chain           |
      | Medium            | HR Investigation Report                 |
      | Low               | Employee Handbook                       |
    And I should be able to drag documents between strength categories
    And my evidence organization should be saved for my team

  @tag_management
  Scenario: Add custom tags to organize evidence
    Given I am viewing the evidence vault
    When I select "Mitchell Performance Reviews"
    And I add custom tags "retaliation, performance-decline, post-complaint"
    And I save the tags
    Then the document should show the new tags
    And I should be able to filter by the custom tag "retaliation"
    And other team members should see the tags I added

  @bulk_operations
  Scenario: Perform bulk operations on selected documents
    Given I am viewing the evidence vault
    When I select multiple documents:
      | document_title                  |
      | Sarah Mitchell's Email Chain    |
      | HR Investigation Report         |
      | Mitchell Performance Reviews    |
    And I choose "Add to Evidence Bundle" from bulk actions
    And I name the bundle "Retaliation Evidence Package"
    Then I should see a new evidence bundle created
    And the bundle should contain all selected documents
    And I should be able to share the bundle with my team

  @access_control_verification
  Scenario: Verify document access restrictions
    Given I am viewing the evidence vault
    Then I should see documents available to my team level:
      | document_title                  | access_level    | should_see |
      | Employee Handbook               | case_teams      | yes        |
      | Expert Damages Assessment       | team_restricted | yes        |
      | TechFlow Financial Records      | instructor_only | no         |
    When I try to access "TechFlow Financial Records" directly
    Then I should see an access denied message
    And I should be redirected back to the evidence vault

  @real_time_collaboration
  Scenario: See real-time updates from team members
    Given I am viewing the evidence vault
    And my teammate "Bob Smith" is also viewing the evidence vault
    When Bob adds a new annotation to "HR Investigation Report"
    Then I should see a real-time notification about the new annotation
    And the document should show an updated annotation indicator
    When Bob uploads a new document "Witness Statement - John Doe"
    Then I should see the new document appear in my vault without refreshing

  @mobile_responsive
  Scenario: Use evidence vault on mobile device
    Given I am viewing the evidence vault on a mobile device
    Then the interface should be mobile-friendly with:
      | feature                         | mobile_behavior                 |
      | Document list                   | Stacked cards instead of table  |
      | Search interface                | Collapsible search panel        |
      | Category filters                | Dropdown instead of sidebar     |
      | Document preview                | Full-screen modal               |
      | Annotation interface            | Touch-friendly controls         |

  @integration_with_case_timeline
  Scenario: View evidence in chronological case timeline
    Given I am viewing the evidence vault
    When I switch to "Timeline View"
    Then I should see documents organized chronologically by:
      | time_period        | documents                               |
      | January 2024       | Mitchell joins TechFlow                 |
      | March-July 2024    | Sarah Mitchell's Email Chain           |
      | August 2024        | HR Investigation Report                 |
      | September 2024     | Mitchell Performance Reviews            |
    And I should be able to filter timeline by document category
    And clicking on a timeline item should open the document preview

  @evidence_export
  Scenario: Export evidence bundles for case preparation
    Given I am viewing the evidence vault
    And I have created an evidence bundle "Harassment Evidence"
    When I select "Export Bundle" for "Harassment Evidence"
    Then I should see export options:
      | format    | description                           |
      | PDF       | Combined PDF with all documents       |
      | ZIP       | Individual files in organized folders|
      | INDEX     | Annotated index with references       |
    When I choose "PDF" export
    Then I should receive a download link
    And the exported PDF should include all bundle documents with annotations