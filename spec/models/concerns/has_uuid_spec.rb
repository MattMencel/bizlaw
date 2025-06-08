# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HasUuid, type: :concern do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new(ApplicationRecord) do
      self.table_name = 'users' # Use existing table for testing
      include HasUuid
    end
  end

  let(:test_instance) { test_class.new }

  describe 'included behavior' do
    it 'generates UUID on creation' do
      expect(test_instance.id).to be_nil
      test_instance.save!
      expect(test_instance.id).to be_present
      expect(test_instance.id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i)
    end

    it 'does not override existing UUID' do
      existing_uuid = SecureRandom.uuid
      test_instance.id = existing_uuid
      test_instance.save!
      expect(test_instance.id).to eq(existing_uuid)
    end

    it 'generates different UUIDs for different instances' do
      instance1 = test_class.create!
      instance2 = test_class.create!

      expect(instance1.id).not_to eq(instance2.id)
      expect(instance1.id).to be_present
      expect(instance2.id).to be_present
    end

    it 'handles UUID format validation' do
      # Valid UUID should work
      valid_uuid = '123e4567-e89b-12d3-a456-426614174000'
      test_instance.id = valid_uuid
      expect(test_instance).to be_valid

      # Invalid format should be handled by database constraints
      # (This would typically fail at the database level, not model validation)
    end
  end

  describe 'shared examples' do
    # Test with actual model that includes the concern
    subject { create(:user) }

    it_behaves_like 'has_uuid'
  end

  describe 'UUID properties' do
    let(:instance) { test_class.create! }

    it 'generates version 4 UUID' do
      # Version 4 UUIDs have '4' as the first character of the third group
      uuid_parts = instance.id.split('-')
      expect(uuid_parts[2][0]).to eq('4')
    end

    it 'generates UUID with correct variant bits' do
      # The first character of the fourth group should be 8, 9, A, or B
      uuid_parts = instance.id.split('-')
      expect(uuid_parts[3][0]).to match(/[89ab]/i)
    end

    it 'generates 36-character UUID including hyphens' do
      expect(instance.id.length).to eq(36)
      expect(instance.id.count('-')).to eq(4)
    end
  end

  describe 'database integration' do
    it 'works with database queries' do
      instance = test_class.create!
      found_instance = test_class.find(instance.id)
      expect(found_instance).to eq(instance)
    end

    it 'supports UUID-based associations' do
      # This would be tested with actual associated models
      # For now, just verify the ID is suitable for foreign key relationships
      instance = test_class.create!
      expect(instance.id).to be_a(String)
      expect(instance.id).to be_present
    end
  end

  describe 'edge cases' do
    it 'handles bulk operations' do
      instances = test_class.create!([ {}, {}, {} ])

      expect(instances.length).to eq(3)
      instances.each do |instance|
        expect(instance.id).to be_present
        expect(instance.id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i)
      end

      # All UUIDs should be unique
      ids = instances.map(&:id)
      expect(ids.uniq.length).to eq(3)
    end

    it 'works with transactions' do
      uuid = nil

      test_class.transaction do
        instance = test_class.create!
        uuid = instance.id
        expect(uuid).to be_present
      end

      # Verify UUID persists after transaction
      found_instance = test_class.find(uuid)
      expect(found_instance.id).to eq(uuid)
    end
  end
end
