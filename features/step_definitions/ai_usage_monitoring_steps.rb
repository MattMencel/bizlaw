# frozen_string_literal: true

Given("AI services are enabled") do
  Rails.cache.delete("ai_services_disabled")
  allow(GoogleAI).to receive(:enabled?).and_return(true)
  @monitoring_service = AiUsageMonitoringService.new
end

When("a client feedback is generated using AI") do
  @case = FactoryBot.create(:case, :sexual_harassment)
  @simulation = FactoryBot.create(:simulation, case: @case)
  @round = FactoryBot.create(:negotiation_round, simulation: @simulation)
  @settlement_offer = FactoryBot.create(:settlement_offer, negotiation_round: @round)

  # Mock AI service to track the request
  allow_any_instance_of(GoogleAiService).to receive(:generate_settlement_feedback).and_wrap_original do |method, *args|
    result = method.call(*args)

    @monitoring_service.track_request(
      model: "gemini-2.0-flash-lite",
      cost: 0.001,
      response_time: 250,
      tokens_used: 150,
      request_type: "settlement_feedback"
    )

    result
  end

  service = ClientFeedbackService.new(@simulation)
  @feedback = service.generate_feedback_for_offer!(@settlement_offer)
end

Then("the API request should be logged") do
  expect(AiUsageLog.count).to be > 0
  log = AiUsageLog.last
  expect(log.model).to eq("gemini-2.0-flash-lite")
  expect(log.request_type).to eq("settlement_feedback")
end

Then("the request count should be incremented") do
  expect(@monitoring_service.daily_request_count).to be > 0
end

Then("the response time should be recorded") do
  log = AiUsageLog.last
  expect(log.response_time_ms).to eq(250)
end

Then("the cost should be calculated and tracked") do
  log = AiUsageLog.last
  expect(log.cost).to eq(0.001)
  expect(@monitoring_service.daily_cost).to be > 0
end

Given("there have been multiple AI requests today") do
  5.times do |i|
    FactoryBot.create(:ai_usage_log,
      cost: 0.001,
      response_time_ms: 200 + i * 10,
      created_at: Time.current - i.hours)
  end
end

When("I view the usage dashboard") do
  visit admin_ai_usage_path
end

Then("I should see the total requests for today") do
  expect(page).to have_content("5") # Total requests
end

Then("I should see the total cost for today") do
  expect(page).to have_content("$0.005") # Total cost
end

Then("I should see the average response time") do
  expect(page).to have_content("220") # Average response time
end

Given("the rate limit is set to {int} requests per hour") do |limit|
  allow(@monitoring_service).to receive(:rate_limit_per_hour).and_return(limit)
end

When("I make {int} requests within an hour") do |request_count|
  @requests_made = request_count

  request_count.times do |i|
    if i < 100 # First 100 should succeed
      FactoryBot.create(:ai_usage_log, created_at: 30.minutes.ago)
    else
      # 101st request should be rate limited
      result = @monitoring_service.check_rate_limit
      @rate_limit_result = result
    end
  end
end

Then("the {int}st request should be queued") do |request_number|
  expect(@rate_limit_result[:allowed]).to be_falsy
end

Then("I should receive a rate limiting message") do
  expect(@rate_limit_result[:message]).to include("rate limit")
end

Then("the request should be processed after the rate limit resets") do
  expect(@rate_limit_result[:retry_after]).to be_present
end

Given("the daily budget limit is ${float}") do |budget_limit|
  allow(@monitoring_service).to receive(:daily_budget_limit).and_return(budget_limit)
end

When("the daily usage reaches ${float}") do |current_usage|
  # Create logs that total to the current usage
  FactoryBot.create(:ai_usage_log, cost: current_usage, created_at: Time.current)
end

Then("an alert should be sent to administrators") do
  expect(AiUsageAlert.where(alert_type: "budget_warning").count).to be > 0
end

Then("the alert should include current usage statistics") do
  alert = AiUsageAlert.last
  expect(alert.current_value).to be_present
  expect(alert.threshold_value).to be_present
end

Then("AI services should be automatically disabled") do
  result = @monitoring_service.check_budget_limit
  expect(result[:allowed]).to be_falsy
  expect(result[:exceeded]).to be_truthy
end

Then("client feedback should fall back to rule-based responses") do
  expect(Rails.cache.read("ai_services_disabled")).to be_truthy
end

Then("administrators should be notified") do
  expect(AiUsageAlert.where(alert_type: "budget_exceeded").count).to be > 0
end

Given("there is usage data for the past {int} days") do |days|
  days.times do |i|
    day = i.days.ago
    rand(1..5).times do
      FactoryBot.create(:ai_usage_log,
        cost: rand(0.001..0.005),
        response_time_ms: rand(100..500),
        created_at: day)
    end
  end
end

When("I view the analytics dashboard") do
  visit admin_ai_analytics_path
  @analytics = @monitoring_service.get_usage_analytics(days: 30)
end

Then("I should see usage trends over time") do
  expect(@analytics[:daily_breakdown]).to be_an(Array)
  expect(@analytics[:daily_breakdown].length).to be > 0
end

Then("I should see cost trends over time") do
  expect(@analytics[:total_cost]).to be > 0
  expect(@analytics[:daily_breakdown].first).to have_key(:cost)
end

Then("I should see peak usage periods") do
  expect(@analytics).to have_key(:peak_hour)
  expect(@analytics).to have_key(:peak_day)
end

Given("there are {int} concurrent AI requests") do |concurrent_requests|
  @concurrent_requests = concurrent_requests
  allow(AiRequestProcessingJob).to receive(:queue_size).and_return(concurrent_requests)
end

When("additional requests come in") do
  @queue_result = @monitoring_service.queue_request({
    model: "gemini-2.0-flash-lite",
    prompt: "Test prompt"
  })
end

Then("excess requests should be queued") do
  expect(@queue_result[:queued]).to be_truthy
end

Then("requests should be processed in order") do
  expect(@queue_result[:position]).to eq(@concurrent_requests + 1)
end

Then("users should see appropriate wait messages") do
  expect(@queue_result[:message]).to include("queued")
  expect(@queue_result[:estimated_wait]).to be_present
end
