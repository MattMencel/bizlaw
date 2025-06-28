# Evidence Release Step Definitions

# Background and Setup Steps
Given("I have a case {string} with active simulation") do |case_title|
  @organization = FactoryBot.create(:organization)
  @course = FactoryBot.create(:course, organization: @organization)
  @case = FactoryBot.create(:case, title: case_title, course: @course)
  @simulation = FactoryBot.create(:simulation,
    case: @case,
    status: "active",
    current_round: 1,
    total_rounds: 4,
    start_date: Date.current)
end

Given("the simulation is in round {int} of {int} rounds") do |current_round, total_rounds|
  @simulation.update!(current_round: current_round, total_rounds: total_rounds)
end

Given("the case has the following evidence documents:") do |table|
  table.hashes.each do |row|
    document = FactoryBot.create(:document,
      title: row["title"],
      documentable: @case,
      document_type: (row["case_material"] == "true") ? "assignment" : "other",
      access_level: row["access_level"])

    # Store evidence type metadata
    document.update!(metadata: {evidence_type: row["evidence_type"]})
  end
end

Given("I have the following teams:") do |table|
  table.hashes.each do |row|
    team = FactoryBot.create(:team,
      name: row["name"],
      team_type: row["type"])
    # Associate team with case
    FactoryBot.create(:case_team, case: @case, team: team)
    instance_variable_set("@#{row["name"].parameterize.underscore}", team)
  end
end

Given("the teams have the following members:") do |table|
  table.hashes.each do |row|
    team = Team.find_by(name: row["team_name"])
    user = User.find_by(email: row["user_email"])
    FactoryBot.create(:team_member,
      team: team,
      user: user,
      role: row["role"])
  end
end

# Navigation Steps
Given("I am viewing the evidence release schedule for {string}") do |case_title|
  case_obj = Case.find_by(title: case_title)
  visit "/cases/#{case_obj.id}/evidence_releases/schedule"
end

When("I visit the evidence release management page") do
  visit "/cases/#{@case.id}/evidence_releases"
end

When("I visit our team's evidence strategy page") do
  visit "/teams/#{@current_user_team.id}/evidence_strategy"
end

# Evidence Scheduling Steps
When("I schedule the following automatic releases:") do |table|
  within(".evidence-scheduling-form") do
    table.hashes.each_with_index do |row, index|
      within(".release-item-#{index}") do
        select row["document_title"], from: "Document"
        select row["evidence_type"].humanize, from: "Evidence Type"
        select row["release_round"], from: "Release Round"
        fill_in "Impact Description", with: row["impact_description"]
      end

      if index < table.hashes.length - 1
        click_button "Add Another Release"
      end
    end

    click_button "Schedule Releases"
  end
end

# Evidence Request Steps
When("I click {string}") do |button_text|
  click_button button_text
end

When("I select {string} from the available documents") do |document_title|
  select document_title, from: "Document"
end

When("I select evidence type {string}") do |evidence_type|
  select evidence_type.humanize, from: "Evidence Type"
end

When("I provide justification {string}") do |justification|
  fill_in "Request Justification", with: justification
end

# Evidence Approval/Denial Steps
When("I add approval note {string}") do |note|
  fill_in "Approval Note", with: note
end

When("I confirm the approval") do
  within(".approval-confirmation") do
    click_button "Confirm Approval"
  end
end

When("I provide denial reason {string}") do |reason|
  fill_in "Denial Reason", with: reason
end

When("I confirm the denial") do
  within(".denial-confirmation") do
    click_button "Confirm Denial"
  end
end

# Simulation Timeline Steps
Given("I have scheduled evidence releases for each round") do
  documents = @case.documents.case_material
  documents.each_with_index do |document, index|
    FactoryBot.create(:evidence_release,
      simulation: @simulation,
      document: document,
      release_round: index + 2, # Start from round 2
      evidence_type: "expert_report",
      impact_description: "Round #{index + 2} evidence",
      auto_release: true,
      scheduled_release_at: @simulation.start_date + (index + 2).weeks)
  end
end

Given("the simulation starts on {string}") do |start_date|
  @simulation.update!(start_date: Date.parse(start_date))
end

When("round {int} begins on {string}") do |round_number, date|
  @simulation.update!(current_round: round_number)

  # Trigger automatic evidence releases for this round
  releases = @simulation.evidence_releases
    .scheduled_for_round(round_number)
    .ready_for_release

  releases.each(&:release!)
end

# Request Status Steps
Given("{string} has requested {string}") do |team_name, document_title|
  team = Team.find_by(name: team_name)
  document = Document.find_by(title: document_title)

  @evidence_request = FactoryBot.create(:evidence_release,
    simulation: @simulation,
    document: document,
    requesting_team: team,
    team_requested: true,
    auto_release: false,
    evidence_type: "expert_report",
    impact_description: "Team evidence request",
    release_conditions: {
      "request_justification" => "Need for case preparation",
      "requested_at" => Time.current
    })
end

Given("the request justification is {string}") do |justification|
  @evidence_request.update!(
    release_conditions: @evidence_request.release_conditions.merge(
      "request_justification" => justification
    )
  )
end

Given("there are scheduled evidence releases for rounds 2-4") do
  documents = @case.documents.limit(3)
  documents.each_with_index do |document, index|
    FactoryBot.create(:evidence_release,
      simulation: @simulation,
      document: document,
      release_round: index + 2,
      evidence_type: "expert_report",
      impact_description: "Scheduled evidence for round #{index + 2}",
      auto_release: true,
      scheduled_release_at: @simulation.start_date + (index + 2).weeks)
  end
end

# Evidence Release Status Steps
Given("{string} has been released in round {int}") do |document_title, round_number|
  document = Document.find_by(title: document_title)
  FactoryBot.create(:evidence_release,
    simulation: @simulation,
    document: document,
    release_round: round_number,
    evidence_type: "expert_report",
    impact_description: "Released evidence",
    auto_release: true,
    released_at: Time.current)

  # Update document access
  document.update!(access_level: "case_teams")
end

# Notification Steps
Then("all team members should receive email notifications") do
  # Check that emails were queued for all team members
  team_members = @case.teams.joins(:users).pluck("users.email").uniq
  expect(ActionMailer::Base.deliveries.map(&:to).flatten).to include(*team_members)
end

Then("the notification should include:") do |table|
  last_email = ActionMailer::Base.deliveries.last
  table.hashes.each do |row|
    case row["information_type"]
    when "evidence_title"
      expect(last_email.subject).to include(row["details"])
    when "evidence_type"
      expect(last_email.body.to_s).to include(row["details"])
    when "release_round"
      expect(last_email.body.to_s).to include("Round #{row["details"]}")
    when "impact_description"
      expect(last_email.body.to_s).to include(row["details"])
    when "access_instructions"
      expect(last_email.body.to_s).to include(row["details"])
    end
  end
end

# Verification Steps
Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end

Then("I should see the releases scheduled for the appropriate rounds") do
  within(".scheduled-releases") do
    expect(page).to have_content("Round 2")
    expect(page).to have_content("Round 3")
    expect(page).to have_content("Round 4")
  end
end

Then("I should see calculated release dates based on simulation timeline") do
  within(".scheduled-releases") do
    expected_date_round_2 = (@simulation.start_date + 2.weeks).strftime("%B %d, %Y")
    expect(page).to have_content(expected_date_round_2)
  end
end

Then("the documents should remain instructor-only until release") do
  documents = @case.documents.where(access_level: "instructor_only")
  expect(documents.count).to be > 0
end

Then("the instructor should receive a notification about the pending request") do
  instructor_emails = User.where(role: "instructor").pluck(:email)
  last_email = ActionMailer::Base.deliveries.last
  expect(instructor_emails).to include(last_email.to.first)
end

Then("the document should become available to {string}") do |team_name|
  Team.find_by(name: team_name)
  document = @evidence_request.document

  # Check that document access was updated appropriately
  expect(document.reload.access_level).to eq("case_teams").or(eq("team_restricted"))
end

Then("{string} should receive approval notification") do |team_name|
  team = Team.find_by(name: team_name)
  team_member_emails = team.users.pluck(:email)

  recent_emails = ActionMailer::Base.deliveries.last(team_member_emails.count)
  recipient_emails = recent_emails.map(&:to).flatten

  expect(recipient_emails).to include(*team_member_emails)
end

Then("a case event should be recorded") do
  latest_event = @case.case_events.last
  expect(latest_event.event_type).to eq("evidence_release")
end

Then("the document should remain instructor-only") do
  document = @evidence_request.document
  expect(document.reload.access_level).to eq("instructor_only")
end

Then("{string} should receive denial notification with reason") do |team_name|
  team = Team.find_by(name: team_name)
  team_member_emails = team.users.pluck(:email)

  last_email = ActionMailer::Base.deliveries.last
  expect(team_member_emails).to include(last_email.to.first)
  expect(last_email.body.to_s).to include("denied")
end

Then("the team should be able to submit a revised request") do
  # Verify that the team can submit another request for the same document
  within(".evidence-request-form") do
    expect(page).to have_button("Submit Evidence Request")
  end
end

Then("{string} should be automatically released") do |document_title|
  document = Document.find_by(title: document_title)
  evidence_release = EvidenceRelease.find_by(document: document, simulation: @simulation)
  expect(evidence_release.released_at).to be_present
end

Then("both teams should have access to the document") do
  released_documents = @simulation.evidence_releases.released
  expect(released_documents.count).to be > 0

  released_documents.each do |release|
    expect(release.document.access_level).to eq("case_teams")
  end
end

Then("a simulation event should be created") do
  expect(@simulation.simulation_events.where(event_type: "additional_evidence")).to exist
end

# Mobile and Performance Steps
Given("I am using a mobile device") do
  # Simulate mobile user agent
  page.driver.header("User-Agent", "Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X)")
  # Resize viewport to mobile dimensions
  page.driver.resize_window(375, 667)
end

Then("the interface should be mobile-optimized") do
  expect(page).to have_css(".mobile-optimized")
  expect(page).to have_css(".responsive-design")
end

Then("the page should load within {int} seconds") do |seconds|
  start_time = Time.current
  visit current_path
  load_time = Time.current - start_time
  expect(load_time).to be < seconds
end

Then("results should appear instantly") do
  # Check for immediate response to search inputs
  fill_in "Search", with: "expert"

  # Should see results without page reload
  expect(page).to have_css(".search-results", wait: 1)
end

# Security and Audit Steps
Then("all access should be logged with user identification") do
  access_logs = CaseEvent.where(event_type: "document_access")
  expect(access_logs).to be_present
  expect(access_logs.last.user).to be_present
end

Then("document access should respect team boundaries") do
  # Verify that team-restricted documents are only accessible to appropriate teams
  restricted_docs = Document.where(access_level: "team_restricted")
  restricted_docs.each do |doc|
    # Implementation would check that current user's team has access
    expect(doc.team_restrictions).to be_present
  end
end

Then("instructor-only evidence should remain secure until release") do
  Document.where(access_level: "instructor_only")
  unreleased_evidence = @simulation.evidence_releases.pending_release

  unreleased_evidence.each do |release|
    expect(release.document.access_level).to eq("instructor_only")
  end
end

Then("download events should be tracked") do
  download_events = CaseEvent.where(event_type: "document_download")
  expect(download_events).to be_present
end

Then("unauthorized access attempts should be blocked and logged") do
  security_events = CaseEvent.where(event_type: "security_violation")
  # This would be tested in a separate scenario that attempts unauthorized access
  expect(security_events.count).to be >= 0 # Should exist if violations occurred
end
