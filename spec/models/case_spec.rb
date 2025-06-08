# frozen_string_literal: true

require "rails_helper"

RSpec.describe Case, type: :model do
  subject(:kase) { build(:case) }

  # Test concerns
  it_behaves_like "has_uuid"
  it_behaves_like "has_timestamps"
  it_behaves_like "soft_deletable"

  # Associations
  describe "associations" do
    it { is_expected.to belong_to(:created_by).class_name("User") }
    it { is_expected.to belong_to(:updated_by).class_name("User") }
    it { is_expected.to belong_to(:course).optional }
    it { is_expected.to belong_to(:team) }
    it { is_expected.to belong_to(:case_type) }
    it { is_expected.to have_many(:documents).dependent(:destroy) }
    it { is_expected.to have_many(:case_events).dependent(:destroy) }
  end

  # Validations
  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(255) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:difficulty_level) }
    it { is_expected.to validate_presence_of(:created_by_id) }
    it { is_expected.to validate_presence_of(:updated_by_id) }
    it { is_expected.to validate_presence_of(:team) }
    it { is_expected.to validate_presence_of(:case_type) }
  end

  # Enums
  describe "enums" do
    it { expect(subject).to define_enum_for(:status).with_values(
      not_started: 'not_started',
      in_progress: 'in_progress',
      submitted: 'submitted',
      reviewed: 'reviewed',
      completed: 'completed'
    ).with_prefix(true) }

    it { is_expected.to define_enum_for(:difficulty_level).with_values(beginner: "beginner", intermediate: "intermediate", advanced: "advanced").with_prefix(true) }
  end

  # Scopes
  describe "scopes" do
    let!(:draft_case) { create(:case, :draft) }
    let!(:published_case) { create(:case, :published) }
    let!(:archived_case) { create(:case, :archived) }
    let!(:beginner_case) { create(:case, :beginner) }
    let!(:advanced_case) { create(:case, :advanced) }

    describe ".by_status" do
      it "returns cases with specified status" do
        expect(described_class.by_status(:draft)).to include(draft_case)
        expect(described_class.by_status(:draft)).not_to include(published_case, archived_case)
      end
    end

    describe ".by_difficulty" do
      it "returns cases with specified difficulty level" do
        expect(described_class.by_difficulty(:beginner)).to include(beginner_case)
        expect(described_class.by_difficulty(:beginner)).not_to include(advanced_case)
      end
    end

    describe "status scopes" do
      it "filters by published status" do
        expect(described_class.published).to include(published_case)
        expect(described_class.published).not_to include(draft_case, archived_case)
      end

      it "filters by draft status" do
        expect(described_class.drafts).to include(draft_case)
        expect(described_class.drafts).not_to include(published_case, archived_case)
      end

      it "filters by archived status" do
        expect(described_class.archived).to include(archived_case)
        expect(described_class.archived).not_to include(draft_case, published_case)
      end
    end

    describe ".search_by_title" do
      let!(:case_one) { create(:case, title: "Contract Law Case") }
      let!(:case_two) { create(:case, title: "Criminal Law Case") }

      it "finds cases by partial title match" do
        expect(described_class.search_by_title("contract")).to include(case_one)
        expect(described_class.search_by_title("contract")).not_to include(case_two)
      end

      it "is case insensitive" do
        expect(described_class.search_by_title("CONTRACT")).to include(case_one)
      end
    end

    describe ".created_by" do
      let(:user) { create(:user) }
      let!(:user_case) { create(:case, created_by: user) }
      let!(:other_case) { create(:case) }

      it "returns cases created by specified user" do
        expect(described_class.created_by(user)).to include(user_case)
        expect(described_class.created_by(user)).not_to include(other_case)
      end
    end

    describe ".recent_first" do
      let!(:old_case) { create(:case, created_at: 2.days.ago) }
      let!(:new_case) { create(:case, created_at: 1.day.ago) }

      it "orders cases by creation date descending" do
        expect(described_class.recent_first).to eq([ new_case, old_case ])
      end
    end
  end

  # Instance methods
  describe "#publish!" do
    context "when case is draft" do
      before { kase.status = :draft }

      it "publishes the case" do
        freeze_time do
          expect(kase.publish!).to be true
          expect(kase).to be_published
          expect(kase.published_at).to eq(Time.current)
        end
      end
    end

    context "when case is not draft" do
      before { kase.status = :published }

      it "returns false" do
        expect(kase.publish!).to be false
      end
    end
  end

  describe "#archive!" do
    context "when case is published" do
      before { kase.status = :published }

      it "archives the case" do
        freeze_time do
          expect(kase.archive!).to be true
          expect(kase).to be_archived
          expect(kase.archived_at).to eq(Time.current)
        end
      end
    end

    context "when case is not published" do
      before { kase.status = :draft }

      it "returns false" do
        expect(kase.archive!).to be false
      end
    end
  end

  describe "status predicates" do
    it "correctly identifies draft status" do
      kase.status = :draft
      expect(kase).to be_draft
      expect(kase).not_to be_published
      expect(kase).not_to be_archived
    end

    it "correctly identifies published status" do
      kase.status = :published
      expect(kase).to be_published
      expect(kase).not_to be_draft
      expect(kase).not_to be_archived
    end

    it "correctly identifies archived status" do
      kase.status = :archived
      expect(kase).to be_archived
      expect(kase).not_to be_draft
      expect(kase).not_to be_published
    end
  end

  describe "#editable?" do
    it "returns true for draft cases" do
      kase.status = :draft
      expect(kase).to be_editable
    end

    it "returns true for published cases" do
      kase.status = :published
      expect(kase).to be_editable
    end

    it "returns false for archived cases" do
      kase.status = :archived
      expect(kase).not_to be_editable
    end
  end

  describe "#display_name" do
    it "returns the case title" do
      kase.title = "Test Case"
      expect(kase.display_name).to eq("Test Case")
    end
  end

  # Callbacks
  describe "callbacks" do
    describe "#set_updated_by" do
      let(:user) { create(:user) }

      it "sets updated_by to created_by on creation" do
        kase = build(:case, created_by: user)
        kase.save!
        expect(kase.updated_by).to eq(user)
      end
    end
  end

  describe 'status helpers' do
    let(:case_instance) { create(:case) }

    describe '#started?' do
      it 'returns false when not started' do
        case_instance.status = :not_started
        expect(case_instance).not_to be_started
      end

      it 'returns true when in progress' do
        case_instance.status = :in_progress
        expect(case_instance).to be_started
      end
    end

    describe '#completed?' do
      it 'returns true when completed' do
        case_instance.status = :completed
        expect(case_instance).to be_completed
      end

      it 'returns false when not completed' do
        case_instance.status = :in_progress
        expect(case_instance).not_to be_completed
      end
    end

    describe '#can_submit?' do
      it 'returns true when in progress' do
        case_instance.status = :in_progress
        expect(case_instance).to be_can_submit
      end

      it 'returns false when not in progress' do
        case_instance.status = :not_started
        expect(case_instance).not_to be_can_submit
      end
    end

    describe '#can_review?' do
      it 'returns true when submitted' do
        case_instance.status = :submitted
        expect(case_instance).to be_can_review
      end

      it 'returns false when not submitted' do
        case_instance.status = :in_progress
        expect(case_instance).not_to be_can_review
      end
    end
  end

  describe 'soft deletion' do
    let(:case_instance) { create(:case) }

    it 'can be soft deleted' do
      expect { case_instance.soft_delete }.to change(case_instance, :deleted_at).from(nil)
    end

    it 'can be restored' do
      case_instance.soft_delete
      expect { case_instance.restore }.to change(case_instance, :deleted_at).to(nil)
    end
  end
end
