# frozen_string_literal: true

RSpec.shared_examples "has_uuid" do
  describe "UUID primary key" do
    it "uses UUID as primary key" do
      expect(subject.id).to be_present
      expect(subject.id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i)
    end

    it "generates version 4 UUID" do
      # Version 4 UUIDs have '4' as the first character of the third group
      uuid_parts = subject.id.split("-")
      expect(uuid_parts[2][0]).to eq("4")
    end

    it "generates UUID with correct variant bits" do
      # The first character of the fourth group should be 8, 9, A, or B
      uuid_parts = subject.id.split("-")
      expect(uuid_parts[3][0]).to match(/[89ab]/i)
    end

    it "generates 36-character UUID including hyphens" do
      expect(subject.id.length).to eq(36)
      expect(subject.id.count("-")).to eq(4)
    end

    it "does not change UUID on update" do
      original_id = subject.id

      # Try to update if the model supports it
      if subject.respond_to?(:touch)
        subject.touch
        expect(subject.id).to eq(original_id)
      end
    end

    it "generates unique UUIDs for different instances" do
      factory_name = described_class.name.underscore.to_sym
      instance1 = create(factory_name)
      instance2 = create(factory_name)

      expect(instance1.id).not_to eq(instance2.id)
      expect(instance1.id).to be_present
      expect(instance2.id).to be_present
    end
  end
end
