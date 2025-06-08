Feature: Document Management
  As a team member
  I want to manage documents
  So that I can share and collaborate on case-related files

  Background:
    Given I am a logged in user
    And I am a member of "Legal Team"
    And I have an active case simulation "Contract Case"

  Scenario: Uploading a document to case simulation
    When I upload a document with the following details:
      | title           | description               | file_type |
      | Contract Draft  | Initial contract draft    | pdf       |
    Then I should see a success message "Document was successfully uploaded"
    And the document should be listed in the case simulation files
    And team members should be notified about the new document

  Scenario: Viewing document details
    Given the following documents exist:
      | title           | description           | file_type | uploaded_by |
      | Contract Draft  | Initial contract      | pdf       | current_user|
      | Meeting Notes   | Client meeting notes  | docx      | current_user|
    When I view the document "Contract Draft"
    Then I should see the following document details:
      | Field         | Value           |
      | Title        | Contract Draft  |
      | Description  | Initial contract|
      | Type         | PDF            |
      | Uploaded By  | Current User   |

  Scenario: Adding comments to a document
    Given I have uploaded a document "Contract Draft"
    When I add the following comment to the document:
      """
      Please review section 3.2 regarding liability clauses.
      We might need to adjust the terms.
      """
    Then I should see a success message "Comment was successfully added"
    And the comment should be visible in the document timeline

  Scenario: Updating document metadata
    Given I have uploaded a document "Contract Draft"
    When I update the document with the following details:
      | title              | description                    |
      | Final Contract     | Updated contract with revisions|
    Then I should see a success message "Document was successfully updated"
    And the document details should be updated

  Scenario: Versioning a document
    Given I have uploaded a document "Contract Draft"
    When I upload a new version of the document
    Then I should see a success message "New version was successfully uploaded"
    And I should see 2 versions of the document
    And the latest version should be marked as current

  Scenario: Archiving a document
    Given I have uploaded a document "Contract Draft"
    When I archive the document
    Then I should see a success message "Document was successfully archived"
    And the document should be marked as archived
    And the document should not appear in the active documents list

  Scenario: Searching documents
    Given the following documents exist:
      | title             | description          | tags            |
      | Contract Draft    | Initial contract     | contract, draft |
      | Meeting Minutes   | Team meeting notes   | meeting, notes  |
      | Legal Analysis    | Case analysis doc    | legal, analysis |
    When I search for documents with tag "contract"
    Then I should see "Contract Draft" in the results
    But I should not see "Meeting Minutes" in the results

  Scenario: Document access control
    Given I am a regular member of "Legal Team"
    And there is a restricted document "Confidential Report"
    When I try to access the restricted document
    Then I should see an error message "You do not have permission to view this document"

  Scenario: Bulk document operations
    Given the following documents exist:
      | title             | description          |
      | Contract Draft    | Initial contract     |
      | Meeting Minutes   | Team meeting notes   |
      | Legal Analysis    | Case analysis doc    |
    When I select multiple documents
    And I choose to archive selected documents
    Then I should see a success message "Selected documents were successfully archived"
    And all selected documents should be marked as archived
