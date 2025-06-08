# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveRecord::QueryCounter do
  before do
    described_class.reset!
  end

  describe ".query_count" do
    it "returns 0 when no queries have been tracked" do
      expect(described_class.query_count).to eq(0)
    end

    it "returns the correct count after tracking queries" do
      described_class.track_query(1.5)
      described_class.track_query(2.0)
      expect(described_class.query_count).to eq(2)
    end
  end

  describe ".query_duration" do
    it "returns 0.0 when no queries have been tracked" do
      expect(described_class.query_duration).to eq(0.0)
    end

    it "returns the sum of tracked query durations" do
      described_class.track_query(1.5)
      described_class.track_query(2.0)
      expect(described_class.query_duration).to eq(3.5)
    end
  end

  describe ".reset!" do
    before do
      described_class.track_query(1.5)
      described_class.track_query(2.0)
    end

    it "resets query count to 0" do
      described_class.reset!
      expect(described_class.query_count).to eq(0)
    end

    it "resets query duration to 0.0" do
      described_class.reset!
      expect(described_class.query_duration).to eq(0.0)
    end
  end

  describe ".track_query" do
    it "increments query count" do
      expect {
        described_class.track_query(1.5)
      }.to change { described_class.query_count }.by(1)
    end

    it "adds duration to total" do
      expect {
        described_class.track_query(1.5)
      }.to change { described_class.query_duration }.by(1.5)
    end
  end

  describe "SQL event subscription" do
    let(:event_name) { "sql.active_record" }
    let(:start) { Time.current }
    let(:finish) { start + 2.seconds }
    let(:event_id) { SecureRandom.hex }
    let(:payload) { { name: query_name, sql: "SELECT * FROM users", binds: [] } }
    let(:event) do
      ActiveSupport::Notifications::Event.new(
        event_name, start, finish, event_id, payload
      )
    end

    before do
      described_class.reset!
    end

    context "when query is a schema query" do
      let(:query_name) { "SCHEMA" }

      it "does not track the query" do
        ActiveSupport::Notifications.instrumenter.start(event_name, event_id, payload)
        ActiveSupport::Notifications.instrumenter.finish(event_name, event_id, payload)

        expect(described_class.query_count).to eq(0)
        expect(described_class.query_duration).to eq(0.0)
      end
    end

    context "when query is a transaction query" do
      let(:query_name) { "TRANSACTION" }

      it "does not track the query" do
        ActiveSupport::Notifications.instrumenter.start(event_name, event_id, payload)
        ActiveSupport::Notifications.instrumenter.finish(event_name, event_id, payload)

        expect(described_class.query_count).to eq(0)
        expect(described_class.query_duration).to eq(0.0)
      end
    end

    context "when query is a regular query" do
      let(:query_name) { "User Load" }

      it "tracks the query" do
        ActiveSupport::Notifications.instrumenter.start(event_name, event_id, payload)
        ActiveSupport::Notifications.instrumenter.finish(event_name, event_id, payload)

        expect(described_class.query_count).to eq(1)
        expect(described_class.query_duration).to be > 0
      end
    end
  end
end
