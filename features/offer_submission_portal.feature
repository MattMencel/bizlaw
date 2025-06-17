Feature: Offer Submission Portal
  As a student team member in a legal negotiation simulation
  I want to submit settlement offers with detailed justifications
  So that I can effectively negotiate with the opposing team

  Background:
    Given a sexual harassment simulation case exists with title "Mitchell v. TechFlow Industries"
    And the case has plaintiff and defendant teams assigned
    And I am logged in as a member of the plaintiff team
    And the simulation is in active status with round 1 in progress

  @offer-submission @core
  Scenario: Submit initial settlement offer with monetary amount
    Given I am on the negotiation dashboard for my current case
    When I click on "Submit Settlement Offer"
    Then I should see the offer submission portal
    And I should see a settlement amount input field
    And I should see a justification text area
    And I should see non-monetary terms checkboxes
    When I enter "$300000" in the settlement amount field
    And I enter "Based on our analysis of similar cases and economic damages" in the justification field
    And I click "Submit Offer"
    Then I should see a confirmation message "Settlement offer submitted successfully"
    And my team's offer should be recorded in the current negotiation round
    And the opposing team should be notified of the new offer

  @offer-submission @validation
  Scenario: Attempt to submit offer with invalid amount
    Given I am on the offer submission portal
    When I enter "-50000" in the settlement amount field
    And I enter "Negative settlement amount" in the justification field
    And I click "Submit Offer"
    Then I should see an error message "Settlement amount must be positive"
    And the offer should not be submitted

  @offer-submission @validation
  Scenario: Attempt to submit offer without justification
    Given I am on the offer submission portal
    When I enter "250000" in the settlement amount field
    And I leave the justification field empty
    And I click "Submit Offer"
    Then I should see an error message "Justification is required"
    And the offer should not be submitted

  @offer-submission @non-monetary-terms
  Scenario: Submit offer with non-monetary terms
    Given I am on the offer submission portal
    When I enter "200000" in the settlement amount field
    And I enter "Comprehensive settlement including policy changes" in the justification field
    And I check "Confidentiality Agreement"
    And I check "Policy Reform Requirements"
    And I select "No admission of wrongdoing" from the admission terms dropdown
    And I enter "Positive reference letter required" in the reference terms field
    And I click "Submit Offer"
    Then I should see a confirmation message "Settlement offer with terms submitted successfully"
    And the offer should include all selected non-monetary terms
    And the opposing team should see the complete offer package

  @offer-submission @counter-proposals
  Scenario: Respond to opposing team's settlement offer
    Given the defendant team has submitted an offer of "$75000"
    And I am viewing the negotiation history
    When I click "Respond to Offer" next to the defendant's offer
    Then I should see the counter-proposal interface
    And I should see the defendant's original offer details
    When I enter "$225000" as my counter-offer amount
    And I enter "Your offer is substantially below fair compensation" in the response justification
    And I click "Submit Counter-Offer"
    Then I should see "Counter-offer submitted successfully"
    And my counter-offer should be linked to the defendant's original offer

  @offer-submission @argument-templates
  Scenario: Use argument templates for structured justifications
    Given I am on the offer submission portal
    When I click "Use Argument Template"
    Then I should see template options:
      | Legal Precedent Analysis |
      | Economic Damages Calculation |
      | Settlement Risk Assessment |
      | Client Impact Statement |
    When I select "Economic Damages Calculation" template
    Then the justification field should be pre-populated with:
      """
      ECONOMIC DAMAGES ANALYSIS:
      
      Lost Wages: $[amount]
      Period: [start_date] to [end_date]
      Calculation: [methodology]
      
      Future Earning Capacity: $[amount]
      Basis: [explanation]
      
      Medical/Therapy Costs: $[amount]
      Documentation: [reference]
      
      Pain and Suffering: $[amount]
      Justification: [explanation]
      
      TOTAL CLAIMED DAMAGES: $[total]
      """
    And I should be able to fill in the template fields
    And I should be able to modify the template content

  @offer-submission @client-consultation
  Scenario: Consult with client before submitting offer
    Given I have prepared an offer for "$275000"
    When I click "Consult Client" before submitting
    Then I should see a client consultation interface
    And I should see my client's current mood indicator
    And I should see my client's priorities:
      | Financial Security | High |
      | Justice/Accountability | High |
      | Privacy Protection | Medium |
      | Future Employment | Medium |
    When I present the offer details to my client
    Then I should receive client feedback based on simulation dynamics
    And the client's reaction should influence my team's decision
    And I should be able to proceed with or modify the offer

  @offer-submission @pressure-indicators
  Scenario: View negotiation pressure and timing information
    Given I am on the offer submission portal
    And the simulation is in round 4 of 6
    Then I should see a pressure indicator showing "High Pressure"
    And I should see "Trial date approaching in 4 weeks"
    And I should see my client's stress level indicator
    And I should see settlement probability metrics
    When the pressure level affects my client's acceptable range
    Then I should see updated guidance: "Client more willing to settle quickly"

  @offer-submission @real-time-feedback
  Scenario: Receive immediate feedback after submitting offer
    Given I have submitted an offer of "$320000"
    When the system processes my offer
    Then I should receive client feedback within 30 seconds
    And I should see one of these client reactions:
      | "Client is pleased with this aggressive opening position" |
      | "Client is concerned this may be too high to start negotiations" |
      | "Client feels this is a reasonable starting point" |
    And I should see strategic guidance without revealing opponent information
    And I should see an updated negotiation timeline

  @offer-submission @revision-workflow
  Scenario: Revise and resubmit offer before round deadline
    Given I have submitted an offer of "$280000"
    And the current round is still active
    When I navigate to my submitted offers
    And I click "Revise Offer" next to my current submission
    Then I should be able to modify the settlement amount
    And I should be able to update the justification
    And I should be able to change non-monetary terms
    When I submit the revised offer
    Then the previous offer should be marked as "Superseded"
    And the new offer should become the active submission
    And the opposing team should be notified of the revision

  @offer-submission @deadline-management
  Scenario: Attempt to submit offer after round deadline
    Given the current negotiation round has expired
    When I try to access the offer submission portal
    Then I should see a message "Round 3 has ended - no new offers accepted"
    And the submit button should be disabled
    And I should see information about the next round
    And I should be able to view my previous submissions

  @offer-submission @team-collaboration
  Scenario: Collaborate with team members on offer preparation
    Given I am working on an offer submission
    When I click "Share Draft with Team"
    Then my team members should be notified
    And they should be able to view and comment on the draft
    When a team member adds a comment "Consider adding confidentiality clause"
    Then I should see the comment in real-time
    And I should be able to incorporate the feedback
    And any team member should be able to submit the final offer

  @offer-submission @settlement-calculator
  Scenario: Use integrated settlement calculator
    Given I am on the offer submission portal
    When I click "Settlement Calculator"
    Then I should see damage calculation tools:
      | Lost wages calculator |
      | Future earnings projector |
      | Pain and suffering estimator |
      | Legal cost calculator |
    When I enter my client's salary "$85000" and unemployment period "8 months"
    Then the calculator should compute lost wages "$56667"
    And I should be able to add this to my settlement justification
    And the calculator should help justify my offer amount

  @offer-submission @mobile-responsive
  Scenario: Submit offer from mobile device
    Given I am accessing the portal from a mobile device
    When I navigate to the offer submission portal
    Then the interface should be mobile-optimized
    And all form fields should be easily accessible
    And the submit button should be thumb-friendly
    When I submit an offer using the mobile interface
    Then the submission should work identically to desktop
    And I should receive the same feedback and confirmations