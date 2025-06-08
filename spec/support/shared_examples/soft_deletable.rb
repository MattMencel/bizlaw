# frozen_string_literal: true

RSpec.shared_examples "soft_deletable" do
  describe 'soft deletion functionality' do
    it 'has deleted_at column' do
      expect(subject).to respond_to(:deleted_at)
    end

    it 'responds to soft delete methods' do
      expect(subject).to respond_to(:soft_delete)
      expect(subject).to respond_to(:restore)
      expect(subject).to respond_to(:deleted?)
      expect(subject).to respond_to(:active?)
    end

    it 'starts as active (not deleted)' do
      expect(subject.deleted?).to be false
      expect(subject.active?).to be true
      expect(subject.deleted_at).to be_nil
    end

    describe '#soft_delete' do
      it 'sets deleted_at timestamp' do
        freeze_time do
          subject.soft_delete
          expect(subject.deleted_at).to eq(Time.current)
        end
      end

      it 'marks record as deleted' do
        subject.soft_delete
        expect(subject.deleted?).to be true
        expect(subject.active?).to be false
      end

      it 'persists the deletion timestamp' do
        subject.soft_delete
        subject.reload
        expect(subject.deleted_at).to be_present
      end
    end

    describe '#restore' do
      before { subject.soft_delete }

      it 'clears deleted_at timestamp' do
        subject.restore
        expect(subject.deleted_at).to be_nil
      end

      it 'marks record as active' do
        subject.restore
        expect(subject.deleted?).to be false
        expect(subject.active?).to be true
      end

      it 'persists the restoration' do
        subject.restore
        subject.reload
        expect(subject.deleted_at).to be_nil
      end
    end

    describe 'scopes' do
      let(:factory_name) { described_class.name.underscore.to_sym }
      let!(:active_record) { create(factory_name) }
      let!(:deleted_record) { create(factory_name).tap(&:soft_delete) }

      it 'filters deleted records by default' do
        results = described_class.all
        expect(results).to include(active_record)
        expect(results).not_to include(deleted_record)
      end

      it 'has active scope' do
        if described_class.respond_to?(:active)
          results = described_class.active
          expect(results).to include(active_record)
          expect(results).not_to include(deleted_record)
        end
      end

      it 'has deleted scope' do
        if described_class.respond_to?(:deleted)
          results = described_class.deleted
          expect(results).to include(deleted_record)
          expect(results).not_to include(active_record)
        end
      end

      it 'can access all records with unscoped' do
        results = described_class.unscoped
        expect(results).to include(active_record)
        expect(results).to include(deleted_record)
      end
    end

    describe 'edge cases' do
      it 'handles multiple soft deletes gracefully' do
        first_deletion = nil

        freeze_time do
          subject.soft_delete
          first_deletion = subject.deleted_at
        end

        travel 1.hour do
          subject.soft_delete
          expect(subject.deleted_at).to eq(first_deletion)
        end
      end

      it 'handles restore of non-deleted records gracefully' do
        expect(subject.deleted_at).to be_nil
        subject.restore
        expect(subject.deleted_at).to be_nil
      end
    end
  end
end
