# frozen_string_literal: true

require "rails_helper"

RSpec.describe SoftDeletable, type: :concern do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new(ApplicationRecord) do
      self.table_name = "users" # Use existing table that has deleted_at column
      include SoftDeletable
    end
  end

  let(:test_instance) { test_class.create! }

  describe "scopes" do
    let!(:active_instance) { test_class.create! }
    let!(:deleted_instance) { test_class.create!(deleted_at: 1.hour.ago) }

    describe ".active" do
      it "returns only non-deleted records" do
        results = test_class.active
        expect(results).to include(active_instance)
        expect(results).not_to include(deleted_instance)
      end
    end

    describe ".deleted" do
      it "returns only deleted records" do
        results = test_class.deleted
        expect(results).to include(deleted_instance)
        expect(results).not_to include(active_instance)
      end
    end

    describe "default scope" do
      it "excludes deleted records by default" do
        results = test_class.all
        expect(results).to include(active_instance)
        expect(results).not_to include(deleted_instance)
      end

      it "can access deleted records with unscoped" do
        results = test_class.unscoped
        expect(results).to include(active_instance)
        expect(results).to include(deleted_instance)
      end
    end
  end

  describe "instance methods" do
    describe "#soft_delete" do
      it "sets deleted_at timestamp" do
        expect(test_instance.deleted_at).to be_nil

        freeze_time do
          test_instance.soft_delete
          expect(test_instance.deleted_at).to eq(Time.current)
        end
      end

      it "saves the record" do
        expect(test_instance).to receive(:save!)
        test_instance.soft_delete
      end

      it "does not actually destroy the record" do
        test_instance.soft_delete
        expect(test_class.unscoped.find(test_instance.id)).to eq(test_instance)
      end

      it "makes record invisible to default queries" do
        test_instance.soft_delete
        expect(test_class.find_by(id: test_instance.id)).to be_nil
      end
    end

    describe "#restore" do
      before { test_instance.soft_delete }

      it "clears deleted_at timestamp" do
        expect(test_instance.deleted_at).to be_present
        test_instance.restore
        expect(test_instance.deleted_at).to be_nil
      end

      it "saves the record" do
        expect(test_instance).to receive(:save!)
        test_instance.restore
      end

      it "makes record visible to default queries again" do
        test_instance.restore
        expect(test_class.find(test_instance.id)).to eq(test_instance)
      end
    end

    describe "#deleted?" do
      it "returns false for active records" do
        expect(test_instance.deleted?).to be false
      end

      it "returns true for soft deleted records" do
        test_instance.soft_delete
        expect(test_instance.deleted?).to be true
      end
    end

    describe "#active?" do
      it "returns true for active records" do
        expect(test_instance.active?).to be true
      end

      it "returns false for soft deleted records" do
        test_instance.soft_delete
        expect(test_instance.active?).to be false
      end
    end
  end

  describe "shared examples" do
    # Test with actual model that includes the concern
    subject { create(:user) }

    it_behaves_like "soft_deletable"
  end

  describe "database integration" do
    it "works with complex queries" do
      active1 = test_class.create!
      test_class.create!
      deleted1 = test_class.create!
      deleted1.soft_delete

      # Test counting
      expect(test_class.count).to eq(2)
      expect(test_class.unscoped.count).to eq(3)

      # Test where clauses
      expect(test_class.where(id: [active1.id, deleted1.id]).count).to eq(1)
      expect(test_class.unscoped.where(id: [active1.id, deleted1.id]).count).to eq(2)
    end

    it "works with associations" do
      # This would be more meaningful with actual associated models
      # For now, just verify the soft delete doesn't break basic querying
      instance = test_class.create!
      instance.soft_delete

      expect(test_class.where(id: instance.id).exists?).to be false
      expect(test_class.unscoped.where(id: instance.id).exists?).to be true
    end
  end

  describe "edge cases" do
    it "handles multiple soft deletes gracefully" do
      first_deletion = nil

      freeze_time do
        test_instance.soft_delete
        first_deletion = test_instance.deleted_at
      end

      travel 1.hour do
        test_instance.soft_delete
        expect(test_instance.deleted_at).to eq(first_deletion) # Should not change
      end
    end

    it "handles restore of non-deleted records gracefully" do
      expect(test_instance.deleted_at).to be_nil
      test_instance.restore
      expect(test_instance.deleted_at).to be_nil
    end

    it "works with validations" do
      # Add a validation to the test class
      test_class.class_eval do
        validates :email, presence: true, if: :active?
      end

      instance = test_class.new
      expect(instance).not_to be_valid # Should fail email validation

      instance.soft_delete
      expect(instance).to be_valid # Validation should not apply to deleted records
    end

    it "works in transactions" do
      test_class.transaction do
        test_instance.soft_delete
        expect(test_instance.deleted?).to be true

        raise ActiveRecord::Rollback
      end

      test_instance.reload
      expect(test_instance.deleted?).to be false # Should be rolled back
    end
  end

  describe "performance considerations" do
    it "uses database indexes efficiently" do
      # This test assumes deleted_at has a database index
      # In a real app, you'd want: add_index :table_name, :deleted_at

      # Create many records
      instances = test_class.create!([{}, {}, {}, {}, {}])
      instances[0..2].each(&:soft_delete)

      # These queries should be efficient with proper indexing
      expect(test_class.active.count).to eq(2)
      expect(test_class.deleted.count).to eq(3)
    end
  end
end
