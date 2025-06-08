# frozen_string_literal: true

require "rails_helper"

RSpec.describe MetricsService do
  let(:endpoint) { "test#action" }
  let(:version) { "1" }
  let(:ip) { "192.168.1.1" }

  before do
    allow(StatsD).to receive(:measure)
    allow(StatsD).to receive(:increment)
    allow(StatsD).to receive(:gauge)
    allow(StatsD).to receive(:count)
    allow(StatsD).to receive(:histogram)
    allow(Rails.logger).to receive(:error)
  end

  describe ".track_request" do
    let(:duration) { 100.5 }
    let(:status) { 200 }

    it "tracks request duration and status" do
      described_class.track_request(
        endpoint: endpoint,
        version: version,
        status: status,
        duration: duration
      )

      expect(StatsD).to have_received(:measure).with(
        "api.request.duration",
        duration,
        tags: { endpoint: endpoint, version: version, status: status }
      )

      expect(StatsD).to have_received(:increment).with(
        "api.response.status",
        tags: { endpoint: endpoint, version: version, status: status }
      )
    end

    context "when status is 5xx" do
      let(:status) { 500 }

      it "tracks server error" do
        described_class.track_request(endpoint: endpoint, version: version, status: status, duration: duration)

        expect(StatsD).to have_received(:increment).with(
          "api.errors.server",
          tags: { endpoint: endpoint, version: version, status: status }
        )
      end
    end

    context "when status is 4xx" do
      let(:status) { 400 }

      it "tracks client error" do
        described_class.track_request(endpoint: endpoint, version: version, status: status, duration: duration)

        expect(StatsD).to have_received(:increment).with(
          "api.errors.client",
          tags: { endpoint: endpoint, version: version, status: status }
        )
      end
    end
  end

  describe ".track_db_metrics" do
    let(:query_count) { 10 }
    let(:query_duration) { 50.5 }

    it "tracks database metrics" do
      described_class.track_db_metrics(
        endpoint: endpoint,
        version: version,
        query_count: query_count,
        query_duration: query_duration
      )

      expect(StatsD).to have_received(:count).with(
        "api.database.queries",
        query_count,
        tags: { endpoint: endpoint, version: version }
      )

      expect(StatsD).to have_received(:measure).with(
        "api.database.duration",
        query_duration,
        tags: { endpoint: endpoint, version: version }
      )
    end
  end

  describe ".track_memory_usage" do
    let(:memory) { 256.5 }

    it "tracks memory usage" do
      described_class.track_memory_usage(
        endpoint: endpoint,
        version: version,
        memory: memory
      )

      expect(StatsD).to have_received(:gauge).with(
        "api.memory.usage",
        memory,
        tags: { endpoint: endpoint, version: version }
      )
    end
  end

  describe ".track_error_details" do
    let(:status) { 500 }
    let(:error_data) do
      {
        message: "Internal Server Error",
        backtrace: [ "line1", "line2" ],
        params: { id: 1 }
      }
    end

    it "tracks and logs error details" do
      described_class.track_error_details(
        endpoint: endpoint,
        version: version,
        status: status,
        error_data: error_data
      )

      expect(StatsD).to have_received(:increment).with(
        "api.errors.details",
        tags: {
          endpoint: endpoint,
          version: version,
          status: status,
          error_type: "server_error"
        }
      )

      expect(Rails.logger).to have_received(:error).with(
        "[API Error] endpoint=#{endpoint} version=#{version} status=#{status} error_data=#{error_data.to_json}"
      )
    end
  end

  describe ".anonymize_ip" do
    it "anonymizes IPv4 address" do
      result = described_class.send(:anonymize_ip, "192.168.1.123")
      expect(result).to eq("192.168.1.0")
    end

    it "anonymizes IPv6 address" do
      result = described_class.send(:anonymize_ip, "2001:0db8:85a3:0000:0000:8a2e:0370:7334")
      expect(result).to eq("2001:db8:85a3::")
    end

    it "handles invalid IP addresses" do
      result = described_class.send(:anonymize_ip, "invalid")
      expect(result).to eq("invalid")
    end

    it "handles blank IP addresses" do
      result = described_class.send(:anonymize_ip, nil)
      expect(result).to eq("unknown")
    end
  end
end
