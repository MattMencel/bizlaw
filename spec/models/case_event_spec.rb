# frozen_string_literal: true

require "rails_helper"

RSpec.describe CaseEvent, type: :model do
  subject { build(:case_event) }

  describe "concerns" do
    it_behaves_like "has_uuid"
    it_behaves_like "has_timestamps"
    it_behaves_like "soft_deletable"
  end

  describe "associations" do
    it { is_expected.to belong_to(:case) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:event_type) }
    it { is_expected.to validate_presence_of(:data) }

    describe "data format validation" do
      it "accepts valid JSON hash" do
        subject.data = {action: "test", details: "some details"}
        expect(subject).to be_valid
      end

      it "rejects non-hash data" do
        subject.data = "invalid string"
        expect(subject).not_to be_valid
        expect(subject.errors[:data]).to include("must be a valid JSON object")
      end

      it "rejects array data" do
        subject.data = ["invalid", "array"]
        expect(subject).not_to be_valid
        expect(subject.errors[:data]).to include("must be a valid JSON object")
      end
    end
  end

  describe "enums" do
    it "defines event_type enum with correct values" do
      expect(described_class.event_types).to eq({
        "created" => "created",
        "updated" => "updated",
        "status_changed" => "status_changed",
        "document_added" => "document_added",
        "document_removed" => "document_removed",
        "team_member_added" => "team_member_added",
        "team_member_removed" => "team_member_removed",
        "comment_added" => "comment_added"
      })
    end

    it "creates scopes for each event type" do
      expect(described_class).to respond_to(:event_type_created)
      expect(described_class).to respond_to(:event_type_updated)
      expect(described_class).to respond_to(:event_type_status_changed)
      expect(described_class).to respond_to(:event_type_document_added)
      expect(described_class).to respond_to(:event_type_document_removed)
      expect(described_class).to respond_to(:event_type_team_member_added)
      expect(described_class).to respond_to(:event_type_team_member_removed)
      expect(described_class).to respond_to(:event_type_comment_added)
    end
  end

  describe "callbacks" do
    describe "before_validation :set_default_data" do
      it "sets empty hash as default data when data is nil" do
        event = build(:case_event, data: nil)
        event.valid?
        expect(event.data).to eq({})
      end

      it "does not override existing data" do
        existing_data = {key: "value"}
        event = build(:case_event, data: existing_data)
        event.valid?
        expect(event.data).to eq(existing_data)
      end
    end
  end

  describe "factory" do
    it "creates valid case event" do
      expect(build(:case_event)).to be_valid
    end

    it "creates case event with associations" do
      event = create(:case_event)
      expect(event.case).to be_present
      expect(event.user).to be_present
    end
  end

  describe "data storage" do
    it "stores complex JSON data correctly" do
      complex_data = {
        previous_status: "draft",
        new_status: "published",
        changed_by: "system",
        timestamp: Time.current.iso8601,
        metadata: {
          ip_address: "192.168.1.1",
          user_agent: "Test Browser"
        }
      }

      event = create(:case_event, data: complex_data)
      event.reload

      expect(event.data).to eq(complex_data.stringify_keys)
    end
  end
end
