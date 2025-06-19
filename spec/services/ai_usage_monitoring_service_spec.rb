# frozen_string_literal: true

require "rails_helper"

RSpec.describe AiUsageMonitoringService, type: :service do
  let(:service) { described_class.new }

  describe "#track_request" do
    it "logs API request with details" do
      expect {
        service.track_request(
          model: "gemini-2.0-flash-lite",
          cost: 0.001,
          response_time: 250,
          tokens_used: 150,
          request_type: "settlement_feedback"
        )
      }.to change(AiUsageLog, :count).by(1)
    end

    it "stores request details correctly" do
      log = service.track_request(
        model: "gemini-2.0-flash-lite",
        cost: 0.002,
        response_time: 300,
        tokens_used: 200,
        request_type: "negotiation_analysis"
      )

      expect(log.model).to eq("gemini-2.0-flash-lite")
      expect(log.cost).to eq(0.002)
      expect(log.response_time_ms).to eq(300)
      expect(log.tokens_used).to eq(200)
      expect(log.request_type).to eq("negotiation_analysis")
    end

    it "increments daily request count" do
      expect {
        service.track_request(model: "test", cost: 0.001, response_time: 100)
      }.to change { service.daily_request_count }.by(1)
    end

    it "adds to daily cost total" do
      expect {
        service.track_request(model: "test", cost: 0.005, response_time: 100)
      }.to change { service.daily_cost }.by(0.005)
    end
  end

  describe "#daily_request_count" do
    before do
      # Create some test logs for today
      create(:ai_usage_log, created_at: Time.current)
      create(:ai_usage_log, created_at: Time.current)

      # Create logs for yesterday (should not be counted)
      create(:ai_usage_log, created_at: 1.day.ago)
    end

    it "returns count of requests for current day" do
      expect(service.daily_request_count).to eq(2)
    end
  end

  describe "#daily_cost" do
    before do
      create(:ai_usage_log, cost: 0.001, created_at: Time.current)
      create(:ai_usage_log, cost: 0.002, created_at: Time.current)
      create(:ai_usage_log, cost: 0.003, created_at: 1.day.ago) # Yesterday - should not count
    end

    it "returns total cost for current day" do
      expect(service.daily_cost).to eq(0.003)
    end
  end

  describe "#hourly_request_count" do
    before do
      create(:ai_usage_log, created_at: 30.minutes.ago)
      create(:ai_usage_log, created_at: 45.minutes.ago)
      create(:ai_usage_log, created_at: 2.hours.ago) # Should not be counted
    end

    it "returns count of requests in the last hour" do
      expect(service.hourly_request_count).to eq(2)
    end
  end

  describe "#check_rate_limit" do
    before do
      allow(service).to receive(:rate_limit_per_hour).and_return(10)
    end

    context "when under rate limit" do
      before do
        allow(service).to receive(:hourly_request_count).and_return(5)
      end

      it "returns success status" do
        result = service.check_rate_limit
        expect(result[:allowed]).to be_truthy
        expect(result[:remaining]).to eq(5)
      end
    end

    context "when at rate limit" do
      before do
        allow(service).to receive(:hourly_request_count).and_return(10)
      end

      it "returns rate limited status" do
        result = service.check_rate_limit
        expect(result[:allowed]).to be_falsy
        expect(result[:remaining]).to eq(0)
        expect(result[:retry_after]).to be_present
      end
    end
  end

  describe "#check_budget_limit" do
    before do
      allow(service).to receive(:daily_budget_limit).and_return(5.00)
    end

    context "when under budget limit" do
      before do
        allow(service).to receive(:daily_cost).and_return(2.50)
      end

      it "returns success status" do
        result = service.check_budget_limit
        expect(result[:allowed]).to be_truthy
        expect(result[:remaining_budget]).to eq(2.50)
        expect(result[:percentage_used]).to eq(50)
      end
    end

    context "when approaching budget limit" do
      before do
        allow(service).to receive(:daily_cost).and_return(4.50)
      end

      it "returns warning status" do
        result = service.check_budget_limit
        expect(result[:allowed]).to be_truthy
        expect(result[:warning]).to be_truthy
        expect(result[:percentage_used]).to eq(90)
      end
    end

    context "when over budget limit" do
      before do
        allow(service).to receive(:daily_cost).and_return(5.50)
      end

      it "returns budget exceeded status" do
        result = service.check_budget_limit
        expect(result[:allowed]).to be_falsy
        expect(result[:exceeded]).to be_truthy
        expect(result[:percentage_used]).to eq(110)
      end
    end
  end

  describe "#send_usage_alert" do
    let(:alert_data) do
      {
        type: "budget_warning",
        daily_cost: 4.50,
        daily_limit: 5.00,
        percentage_used: 90
      }
    end

    it "creates an alert record" do
      expect {
        service.send_usage_alert(alert_data)
      }.to change(AiUsageAlert, :count).by(1)
    end

    it "stores alert details" do
      alert = service.send_usage_alert(alert_data)

      expect(alert.alert_type).to eq("budget_warning")
      expect(alert.threshold_value).to eq(90)
      expect(alert.current_value).to eq(4.50)
    end

    it "sends notification to administrators" do
      expect(AdminNotificationService).to receive(:send_ai_usage_alert).with(alert_data)
      service.send_usage_alert(alert_data)
    end

    it "does not send duplicate alerts within time window" do
      service.send_usage_alert(alert_data)

      expect {
        service.send_usage_alert(alert_data)
      }.not_to change(AiUsageAlert, :count)
    end
  end

  describe "#queue_request" do
    it "adds request to processing queue" do
      request_data = {model: "test", prompt: "test prompt"}

      expect(AiRequestProcessingJob).to receive(:perform_later).with(request_data)
      service.queue_request(request_data)
    end

    it "returns queue position" do
      allow(AiRequestProcessingJob).to receive(:queue_size).and_return(5)

      result = service.queue_request({model: "test"})
      expect(result[:queued]).to be_truthy
      expect(result[:position]).to eq(6)
    end
  end

  describe "#get_usage_analytics" do
    before do
      # Create test data for analytics
      create_list(:ai_usage_log, 3, created_at: Date.current.beginning_of_day, cost: 0.001)
      create_list(:ai_usage_log, 2, created_at: 1.day.ago.beginning_of_day, cost: 0.002)
      create_list(:ai_usage_log, 1, created_at: 2.days.ago.beginning_of_day, cost: 0.003)
    end

    it "returns usage data for specified period" do
      analytics = service.get_usage_analytics(days: 3)

      expect(analytics[:total_requests]).to eq(6)
      expect(analytics[:total_cost]).to eq(0.009)
      expect(analytics[:daily_breakdown]).to be_an(Array)
      expect(analytics[:daily_breakdown].length).to eq(3)
    end

    it "includes daily breakdown with correct data" do
      analytics = service.get_usage_analytics(days: 2)

      today_data = analytics[:daily_breakdown].find { |d| d[:date] == Date.current }
      expect(today_data[:requests]).to eq(3)
      expect(today_data[:cost]).to eq(0.003)
    end

    it "calculates average response time" do
      create(:ai_usage_log, response_time_ms: 200, created_at: Time.current)
      create(:ai_usage_log, response_time_ms: 400, created_at: Time.current)

      analytics = service.get_usage_analytics(days: 1)
      expect(analytics[:avg_response_time]).to eq(300)
    end
  end

  describe "#disable_ai_services" do
    it "sets AI services to disabled state" do
      service.disable_ai_services(reason: "Budget exceeded")

      expect(Rails.cache.read("ai_services_disabled")).to be_truthy
      expect(Rails.cache.read("ai_services_disable_reason")).to eq("Budget exceeded")
    end

    it "sends notification about service disable" do
      expect(AdminNotificationService).to receive(:send_ai_service_disabled_alert)
      service.disable_ai_services(reason: "Rate limit exceeded")
    end
  end

  describe "#enable_ai_services" do
    before do
      Rails.cache.write("ai_services_disabled", true)
      Rails.cache.write("ai_services_disable_reason", "Test disable")
    end

    it "enables AI services" do
      service.enable_ai_services

      expect(Rails.cache.read("ai_services_disabled")).to be_falsy
      expect(Rails.cache.read("ai_services_disable_reason")).to be_nil
    end
  end

  describe "#ai_services_enabled?" do
    it "returns true when services are enabled" do
      Rails.cache.delete("ai_services_disabled")
      expect(service.ai_services_enabled?).to be_truthy
    end

    it "returns false when services are disabled" do
      Rails.cache.write("ai_services_disabled", true)
      expect(service.ai_services_enabled?).to be_falsy
    end
  end
end
