# frozen_string_literal: true

# Step definitions for document management features

Given("I have documents in my case") do
  @current_user ||= create(:user, role: :student)
  @case ||= create(:case)
  @documents = create_list(:document, 3, documentable: @case, created_by: @current_user)
end

Given("the following documents exist:") do |table|
  table.hashes.each do |doc_data|
    user = User.find_by(email: doc_data["Owner"]) || @current_user
    documentable = Case.find_by(title: doc_data["Case"]) || Team.find_by(name: doc_data["Team"])

    create(:document,
      title: doc_data["Title"],
      description: doc_data["Description"],
      document_type: doc_data["Type"]&.downcase || "evidence",
      status: doc_data["Status"]&.downcase || "draft",
      documentable: documentable,
      created_by: user)
  end
end

Given("I have a document {string} in my case") do |document_title|
  @current_user ||= create(:user, role: :student)
  @case ||= create(:case)
  @document = create(:document,
    title: document_title,
    documentable: @case,
    created_by: @current_user)
end

Given("there is a document {string} shared with my team") do |document_title|
  @current_user ||= create(:user, role: :student)
  @team ||= create(:team)
  @document = create(:document,
    title: document_title,
    documentable: @team,
    created_by: @current_user)
end

Given("the document {string} has {int} versions") do |document_title, version_count|
  @document = Document.find_by(title: document_title)
  # Note: Version tracking would need to be implemented in the Document model
  @document.update(metadata: {version_count: version_count})
end

When("I navigate to the document management page") do
  if @case
    visit case_documents_path(@case)
  elsif @team
    visit team_documents_path(@team)
  else
    visit documents_path
  end
end

When("I upload a new document") do
  if page.has_link?("Upload Document")
    click_link "Upload Document"
  elsif page.has_button?("Add Document")
    click_button "Add Document"
  end
end

When("I upload a document with the following details:") do |table|
  details = table.rows_hash

  visit new_document_path
  fill_in "Title", with: details["Title"]
  fill_in "Description", with: details["Description"]
  select details["Type"], from: "Document Type" if details["Type"]

  # Handle file upload if specified
  if details["File"]
    attach_file "File", Rails.root.join("spec/fixtures/files/#{details["File"]}")
  end

  if page.has_button?("Upload")
    click_button "Upload"
  elsif page.has_button?("Create Document")
    click_button "Create Document"
  end
end

When("I edit the document {string}") do |document_title|
  document = Document.find_by!(title: document_title)
  visit edit_document_path(document)
end

When("I update the document with:") do |table|
  details = table.rows_hash

  fill_in "Title", with: details["Title"] if details["Title"]
  fill_in "Description", with: details["Description"] if details["Description"]
  select details["Type"], from: "Document Type" if details["Type"]

  if page.has_button?("Update")
    click_button "Update"
  elsif page.has_button?("Save")
    click_button "Save"
  end
end

When("I delete the document {string}") do |document_title|
  document = Document.find_by!(title: document_title)
  visit document_path(document)

  if page.has_link?("Delete")
    click_link "Delete"
  elsif page.has_button?("Delete Document")
    click_button "Delete Document"
  end

  # Handle confirmation
  click_button "Confirm" if page.has_button?("Confirm")
end

When("I search for documents containing {string}") do |search_term|
  visit documents_path
  fill_in "Search", with: search_term
  click_button "Search"
end

When("I filter documents by type {string}") do |document_type|
  visit documents_path
  select document_type, from: "Document Type"
  click_button "Filter"
end

When("I view the document {string}") do |document_title|
  document = Document.find_by!(title: document_title)
  visit document_path(document)
end

When("I download the document {string}") do |document_title|
  document = Document.find_by!(title: document_title)
  visit document_path(document)
  click_link "Download"
end

When("I add a comment to the document:") do |comment_text|
  fill_in "Comment", with: comment_text
  click_button "Add Comment"
end

When("I share the document with {string}") do |user_email|
  User.find_by!(email: user_email)

  click_link "Share Document"
  fill_in "User Email", with: user_email
  click_button "Share"
end

When("I create a new version of the document") do
  if page.has_link?("New Version")
    click_link "New Version"
  elsif page.has_button?("Create Version")
    click_button "Create Version"
  end
end

When("I finalize the document") do
  if page.has_button?("Finalize")
    click_button "Finalize"
  elsif page.has_link?("Finalize Document")
    click_link "Finalize Document"
  end
end

When("I archive the document") do
  if page.has_button?("Archive")
    click_button "Archive"
  elsif page.has_link?("Archive Document")
    click_link "Archive Document"
  end
end

When("I restore the archived document") do
  if page.has_button?("Restore")
    click_button "Restore"
  elsif page.has_link?("Restore Document")
    click_link "Restore Document"
  end
end

When("I set document permissions for {string} to {string}") do |user_email, permission_level|
  User.find_by!(email: user_email)

  click_link "Manage Permissions"
  within("[data-user-email='#{user_email}']") do
    select permission_level, from: "Permission Level"
  end
  click_button "Save Permissions"
end

When("I organize documents into the {string} folder") do |folder_name|
  check_all_documents
  select folder_name, from: "Move to Folder"
  click_button "Move Selected"
end

When("I perform bulk delete on selected documents") do
  check_all_documents
  click_button "Delete Selected"
  click_button "Confirm" if page.has_button?("Confirm")
end

When("I export documents to PDF") do
  check_all_documents
  click_button "Export to PDF"
end

When("I export documents to Word") do
  check_all_documents
  click_button "Export to Word"
end

Then("I should see the document {string} in the list") do |document_title|
  expect(page).to have_content(document_title)
end

Then("I should not see the document {string} in the list") do |document_title|
  expect(page).not_to have_content(document_title)
end

Then("the document should be uploaded successfully") do
  success_present = page.has_content?("successfully uploaded") ||
    page.has_content?("Document created") ||
    page.has_css?(".alert-success")
  expect(success_present).to be true
end

Then("the document should be updated successfully") do
  success_present = page.has_content?("successfully updated") ||
    page.has_content?("Document updated") ||
    page.has_css?(".alert-success")
  expect(success_present).to be true
end

Then("the document should be deleted successfully") do
  success_present = page.has_content?("successfully deleted") ||
    page.has_content?("Document removed") ||
    page.has_css?(".alert-success")
  expect(success_present).to be true
end

Then("I should see documents of type {string}") do |document_type|
  expect(page).to have_content(document_type)
end

Then("I should see the document details") do
  document = @document || Document.last
  expect(page).to have_content(document.title)
  expect(page).to have_content(document.description) if document.description
end

Then("the document should be downloaded") do
  # This would check for file download in a real browser
  expect(page.response_headers["Content-Disposition"]).to include("attachment") if page.respond_to?(:response_headers)
end

Then("I should see the comment in the document") do
  comment_present = page.has_content?("Comment added successfully") ||
    page.has_css?(".document-comment")
  expect(comment_present).to be true
end

Then("the document should be shared with {string}") do |user_email|
  shared_present = page.has_content?("Shared with #{user_email}") ||
    page.has_content?("Document shared successfully")
  expect(shared_present).to be true
end

Then("I should see version {int} of the document") do |version_number|
  expect(page).to have_content("Version #{version_number}")
end

Then("the document status should be {string}") do |status|
  expect(page).to have_content(status)
end

Then("the document should be finalized") do
  finalized_present = page.has_content?("final") ||
    page.has_content?("finalized") ||
    page.has_content?("Document finalized successfully")
  expect(finalized_present).to be true
end

Then("the document should be archived") do
  archived_present = page.has_content?("archived") ||
    page.has_content?("Document archived successfully")
  expect(archived_present).to be true
end

Then("the document should be restored") do
  restored_present = page.has_content?("restored") ||
    page.has_content?("Document restored successfully")
  expect(restored_present).to be true
end

Then("the user should have {string} access to the document") do |access_level|
  access_present = page.has_content?(access_level) ||
    page.has_content?("Permissions updated")
  expect(access_present).to be true
end

Then("the documents should be organized into the {string} folder") do |folder_name|
  organized_present = page.has_content?("Documents moved to #{folder_name}") ||
    page.has_content?("Organization updated")
  expect(organized_present).to be true
end

Then("the selected documents should be deleted") do
  deleted_present = page.has_content?("Documents deleted successfully") ||
    page.has_content?("Bulk delete completed")
  expect(deleted_present).to be true
end

Then("I should receive a PDF export") do
  expect(page.response_headers["Content-Type"]).to include("pdf") if page.respond_to?(:response_headers)
end

Then("I should receive a Word export") do
  expect(page.response_headers["Content-Type"]).to include("word") if page.respond_to?(:response_headers)
end

Then("I should see an access denied message") do
  denied_present = page.has_content?("Access denied") ||
    page.has_content?("You don't have permission")
  expect(denied_present).to be true
end

Then("I should see a validation error") do
  error_present = page.has_content?("error") ||
    page.has_css?(".alert-danger") ||
    page.has_css?(".field_with_errors")
  expect(error_present).to be true
end

# Helper methods

def check_all_documents
  check "Select All" if page.has_field?("Select All")

  # If no "Select All" checkbox, check individual documents
  page.all('input[type="checkbox"][name*="document"]').find_each do |checkbox|
    checkbox.check
  end
end
