# frozen_string_literal: true

require "rails_helper"

RSpec.describe HasTimestamps do
  let(:test_class) do
    Class.new(ApplicationRecord) do
      self.table_name = "users" # Using users table for testing
      include HasTimestamps
    end
  end

  let(:model) { test_class.new }

  describe "validations" do
    it { is_expected.to validate_presence_of(:created_at) }
    it { is_expected.to validate_presence_of(:updated_at) }
  end

  describe "callbacks" do
    it "sets created_at on create" do
      freeze_time do
        model.save!
        expect(model.created_at).to eq(Time.current)
      end
    end

    it "updates updated_at on save" do
      model.save!
      original_time = model.updated_at

      travel 1.day do
        model.save!
        expect(model.updated_at).to be > original_time
      end
    end
  end

  describe "scopes" do
    let!(:old_record) { test_class.create!(created_at: 2.days.ago, updated_at: 2.days.ago) }
    let!(:new_record) { test_class.create!(created_at: 1.day.ago, updated_at: 1.hour.ago) }

    it "filters by created_before" do
      expect(test_class.created_before(1.5.days.ago)).to include(old_record)
      expect(test_class.created_before(1.5.days.ago)).not_to include(new_record)
    end

    it "filters by created_after" do
      expect(test_class.created_after(1.5.days.ago)).to include(new_record)
      expect(test_class.created_after(1.5.days.ago)).not_to include(old_record)
    end

    it "filters by created_between" do
      records = test_class.created_between(3.days.ago, 1.day.ago)
      expect(records).to include(old_record, new_record)
    end

    it "returns recent records" do
      expect(test_class.recent).to eq([new_record, old_record])
    end

    it "returns recently updated records" do
      expect(test_class.recently_updated).to eq([new_record, old_record])
    end
  end

  describe "#created_ago" do
    it "returns human readable time difference" do
      model.created_at = 2.days.ago
      expect(model.created_ago).to eq("2 days")
    end
  end

  describe "#updated_ago" do
    it "returns human readable time difference" do
      model.updated_at = 1.hour.ago
      expect(model.updated_ago).to eq("about 1 hour")
    end
  end

  describe "#touch_with_version" do
    context "when model responds to increment_version" do
      before do
        allow(model).to receive(:increment_version)
      end

      it "calls touch and increment_version" do
        expect(model).to receive(:touch)
        expect(model).to receive(:increment_version)
        model.touch_with_version
      end
    end

    context "when model does not respond to increment_version" do
      it "only calls touch" do
        expect(model).to receive(:touch)
        model.touch_with_version
      end
    end
  end
end
