# frozen_string_literal: true

Given("there is a sexual harassment case with teams assigned") do
  @course = FactoryBot.create(:course)
  @instructor = FactoryBot.create(:user, :instructor)
  @case = FactoryBot.create(:case, :sexual_harassment, course: @course, created_by: @instructor)

  @plaintiff_team = FactoryBot.create(:team, name: "Plaintiff Team")
  @defendant_team = FactoryBot.create(:team, name: "Defendant Team")

  FactoryBot.create(:case_team, case: @case, team: @plaintiff_team, role: "plaintiff")
  FactoryBot.create(:case_team, case: @case, team: @defendant_team, role: "defendant")
end

When("I create a new sexual harassment case") do
  @course = FactoryBot.create(:course)
  @instructor = FactoryBot.create(:user, :instructor)
  @case = FactoryBot.create(:case, :sexual_harassment, course: @course, created_by: @instructor)

  # Assign personalities
  @personalities = PersonalityService.assign_personalities(@case)
  @case.update!(
    plaintiff_info: @case.plaintiff_info.merge(personality_type: @personalities[:plaintiff_personality]),
    defendant_info: @case.defendant_info.merge(personality_type: @personalities[:defendant_personality])
  )
end

Then("the plaintiff client should have a personality assigned") do
  expect(@case.plaintiff_info["personality_type"]).to be_present
  expect(PersonalityService.available_personalities.map { |p| p["type"] }).to include(@case.plaintiff_info["personality_type"])
end

Then("the defendant client should have a personality assigned") do
  expect(@case.defendant_info["personality_type"]).to be_present
  expect(PersonalityService.available_personalities.map { |p| p["type"] }).to include(@case.defendant_info["personality_type"])
end

Then("the personalities should be different from each other") do
  expect(@case.plaintiff_info["personality_type"]).not_to eq(@case.defendant_info["personality_type"])
end

Given("the plaintiff client has an {string} personality") do |personality_type|
  @case.update!(
    plaintiff_info: @case.plaintiff_info.merge(personality_type: personality_type)
  )
  @plaintiff_personality = personality_type
end

Given("the plaintiff client has a {string} personality") do |personality_type|
  step("the plaintiff client has an \"#{personality_type}\" personality")
end

Given("the defendant makes a low settlement offer") do
  @simulation = FactoryBot.create(:simulation, case: @case)
  @round = FactoryBot.create(:negotiation_round, simulation: @simulation, round_number: 1)
  @settlement_offer = FactoryBot.create(:settlement_offer,
    team: @defendant_team,
    negotiation_round: @round,
    amount: 25_000) # Low offer
end

Given("the defendant makes a reasonable settlement offer") do
  @simulation = FactoryBot.create(:simulation, case: @case)
  @round = FactoryBot.create(:negotiation_round, simulation: @simulation, round_number: 1)
  @settlement_offer = FactoryBot.create(:settlement_offer,
    team: @defendant_team,
    negotiation_round: @round,
    amount: 150_000) # Reasonable offer
end

When("I generate client feedback for the offer") do
  service = ClientFeedbackService.new(@simulation)
  @feedback = service.generate_feedback_for_offer!(@settlement_offer)
end

Then("the feedback should use assertive and demanding language") do
  expect(@feedback.feedback_text).to match(/\b(demand|insist|require|unacceptable|insufficient)\b/i)
end

Then("the satisfaction score should reflect aggressive expectations") do
  # Aggressive personalities should have lower satisfaction with low offers
  expect(@feedback.satisfaction_score).to be < 50
end

Then("the mood should be more positive than for an aggressive personality") do
  # For a reasonable offer, cautious personality should be more satisfied than aggressive
  expect(@feedback.mood_level).to be_in(["neutral", "satisfied", "very_satisfied"])
end

Then("the feedback should express measured satisfaction") do
  expect(@feedback.feedback_text).to match(/\b(consider|reasonable|evaluate|acceptable)\b/i)
end

When("I generate multiple client feedbacks during the simulation") do
  @feedbacks = []
  service = ClientFeedbackService.new(@simulation)

  # Generate feedback for multiple rounds
  3.times do |round_num|
    round = FactoryBot.create(:negotiation_round, simulation: @simulation, round_number: round_num + 1)
    offer = FactoryBot.create(:settlement_offer,
      team: @defendant_team,
      negotiation_round: round,
      amount: 100_000 + (round_num * 25_000))

    feedback = service.generate_feedback_for_offer!(offer)
    @feedbacks << feedback
  end
end

Then("all responses should maintain emotional language patterns") do
  @feedbacks.each do |feedback|
    expect(feedback.feedback_text).to match(/\b(feel|emotional|upset|frustrated|concerned)\b/i)
  end
end

Then("the personality traits should be consistent across rounds") do
  # Track consistency
  responses = @feedbacks.map(&:feedback_text)
  tracker = PersonalityService.track_consistency(@case, @plaintiff_personality, responses)

  expect(tracker.consistency_score).to be > 70
end

Given("there are cases with different client personalities") do
  @cases_with_personalities = []

  ["aggressive", "cautious", "emotional", "pragmatic"].each do |personality|
    case_instance = FactoryBot.create(:case, :sexual_harassment, course: @course, created_by: @instructor)
    case_instance.update!(
      plaintiff_info: case_instance.plaintiff_info.merge(personality_type: personality)
    )

    # Set up simulation for each case
    simulation = FactoryBot.create(:simulation, case: case_instance)
    round = FactoryBot.create(:negotiation_round, simulation: simulation, round_number: 1)

    @cases_with_personalities << {
      case: case_instance,
      simulation: simulation,
      round: round,
      personality: personality
    }
  end
end

When("I generate feedback for the same settlement offer across all cases") do
  @personality_responses = {}

  @cases_with_personalities.each do |case_data|
    # Create plaintiff team for this case
    plaintiff_team = FactoryBot.create(:team, name: "Plaintiff Team #{case_data[:personality]}")
    FactoryBot.create(:case_team, case: case_data[:case], team: plaintiff_team, role: "plaintiff")

    offer = FactoryBot.create(:settlement_offer,
      team: plaintiff_team,
      negotiation_round: case_data[:round],
      amount: 125_000) # Same offer amount for all

    service = ClientFeedbackService.new(case_data[:simulation])
    feedback = service.generate_feedback_for_offer!(offer)

    @personality_responses[case_data[:personality]] = feedback
  end
end

Then("each personality should produce distinctly different responses") do
  response_texts = @personality_responses.values.map(&:feedback_text)

  # All responses should be different
  expect(response_texts.uniq.length).to eq(response_texts.length)
end

Then("the language patterns should be personality-appropriate") do
  # Aggressive should use strong language
  expect(@personality_responses["aggressive"].feedback_text).to match(/\b(demand|strong|firm|unacceptable)\b/i)

  # Cautious should use measured language
  expect(@personality_responses["cautious"].feedback_text).to match(/\b(consider|careful|evaluate|review)\b/i)

  # Emotional should use feeling-based language
  expect(@personality_responses["emotional"].feedback_text).to match(/\b(feel|emotional|concerned|worried)\b/i)

  # Pragmatic should use practical language
  expect(@personality_responses["pragmatic"].feedback_text).to match(/\b(practical|realistic|business|sensible)\b/i)
end

Given("the defendant client has a {string} personality") do |personality_type|
  @case.update!(
    defendant_info: @case.defendant_info.merge(personality_type: personality_type)
  )
  @defendant_personality = personality_type
end

When("both receive the same settlement offer") do
  @simulation = FactoryBot.create(:simulation, case: @case)
  @round = FactoryBot.create(:negotiation_round, simulation: @simulation, round_number: 1)

  # Create offer from defendant perspective (offering to plaintiff)
  @settlement_offer = FactoryBot.create(:settlement_offer,
    team: @defendant_team,
    negotiation_round: @round,
    amount: 175_000)

  service = ClientFeedbackService.new(@simulation)

  # Generate feedback from both perspectives
  @plaintiff_feedback = service.generate_feedback_for_offer!(@settlement_offer)

  # For defendant feedback, we need to reverse the perspective
  @defendant_feedback = service.generate_feedback_for_offer!(@settlement_offer, perspective: "defendant")
end

Then("the perfectionist should have lower satisfaction") do
  perfectionist_feedback = (@plaintiff_personality == "perfectionist") ? @plaintiff_feedback : @defendant_feedback
  expect(perfectionist_feedback.satisfaction_score).to be < 75
end

Then("the pragmatic client should have higher satisfaction") do
  pragmatic_feedback = (@plaintiff_personality == "pragmatic") ? @plaintiff_feedback : @defendant_feedback
  expect(pragmatic_feedback.satisfaction_score).to be > 60
end

Given("I have a case with assigned client personalities") do
  step("I create a new sexual harassment case")
end

When("I view the case details") do
  visit case_path(@case)
end

Then("I should see the plaintiff client's personality type") do
  expect(page).to have_content(@case.plaintiff_info["personality_type"])
end

Then("I should see the defendant client's personality type") do
  expect(page).to have_content(@case.defendant_info["personality_type"])
end

Then("I should see personality trait descriptions") do
  plaintiff_personality = PersonalityService.get_personality_traits(@case.plaintiff_info["personality_type"])
  defendant_personality = PersonalityService.get_personality_traits(@case.defendant_info["personality_type"])

  expect(page).to have_content(plaintiff_personality["name"])
  expect(page).to have_content(defendant_personality["name"])
end
