# frozen_string_literal: true

require "rails_helper"

RSpec.describe Case, type: :model do
  subject(:kase) { create(:case) }

  # Test concerns
  it_behaves_like "has_uuid"
  it_behaves_like "has_timestamps"
  it_behaves_like "soft_deletable"

  # Associations
  describe "associations" do
    it { is_expected.to belong_to(:created_by).class_name("User") }
    it { is_expected.to belong_to(:updated_by).class_name("User") }
    it { is_expected.to belong_to(:course) }
    it { is_expected.to have_many(:case_teams).dependent(:destroy) }
    it { is_expected.to have_many(:assigned_teams).through(:case_teams) }
    it { is_expected.to have_many(:teams).through(:case_teams) }
    it { is_expected.to have_many(:documents).dependent(:destroy) }
    it { is_expected.to have_many(:case_events).dependent(:destroy) }
    it { is_expected.to have_one(:simulation).dependent(:destroy) }
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
    it { is_expected.to validate_presence_of(:reference_number) }
    it { is_expected.to validate_presence_of(:plaintiff_info) }
    it { is_expected.to validate_presence_of(:defendant_info) }
    it { is_expected.to validate_presence_of(:legal_issues) }
    it { is_expected.to validate_presence_of(:course_id) }
  end

  # Enums
  describe "enums" do
    it {
      expect(subject).to define_enum_for(:status).with_values(
        not_started: "not_started",
        in_progress: "in_progress",
        submitted: "submitted",
        reviewed: "reviewed",
        completed: "completed"
      ).backed_by_column_of_type(:string).with_prefix(true)
    }

    it { is_expected.to define_enum_for(:difficulty_level).with_values(beginner: "beginner", intermediate: "intermediate", advanced: "advanced").backed_by_column_of_type(:string).with_prefix(true) }

    it { is_expected.to define_enum_for(:case_type).with_values(sexual_harassment: "sexual_harassment", discrimination: "discrimination", wrongful_termination: "wrongful_termination", contract_dispute: "contract_dispute", intellectual_property: "intellectual_property").backed_by_column_of_type(:string).with_prefix(true) }
  end

  # Scopes
  describe "scopes" do
    let!(:not_started_case) { create(:case, status: :not_started) }
    let!(:in_progress_case) { create(:case, status: :in_progress) }
    let!(:completed_case) { create(:case, status: :completed) }
    let!(:beginner_case) { create(:case, difficulty_level: :beginner) }
    let!(:advanced_case) { create(:case, difficulty_level: :advanced) }

    describe ".by_status" do
      it "returns cases with specified status" do
        expect(described_class.by_status(:not_started)).to include(not_started_case)
        expect(described_class.by_status(:not_started)).not_to include(in_progress_case, completed_case)
      end
    end

    describe ".by_difficulty" do
      it "returns cases with specified difficulty level" do
        expect(described_class.by_difficulty(:beginner)).to include(beginner_case)
        expect(described_class.by_difficulty(:beginner)).not_to include(advanced_case)
      end
    end

    describe "status scopes" do
      it "filters by in_progress status" do
        expect(described_class.in_progress_cases).to include(in_progress_case)
        expect(described_class.in_progress_cases).not_to include(not_started_case, completed_case)
      end

      it "filters by completed status" do
        expect(described_class.completed_cases).to include(completed_case)
        expect(described_class.completed_cases).not_to include(not_started_case, in_progress_case)
      end

      it "filters active cases (non-completed)" do
        expect(described_class.active).to include(not_started_case, in_progress_case)
        expect(described_class.active).not_to include(completed_case)
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
        expect(described_class.recent_first).to eq([new_case, old_case])
      end
    end
  end

  # Instance methods
  describe "#archive!" do
    it "archives the case" do
      freeze_time do
        expect(kase.archive!).to be true
        expect(kase).to be_archived
        expect(kase.archived_at).to eq(Time.current)
      end
    end
  end

  describe "status predicates" do
    it "correctly identifies not_started status" do
      kase.status = :not_started
      expect(kase).to be_status_not_started
      expect(kase).not_to be_published
      expect(kase).not_to be_archived
    end

    it "correctly identifies in_progress status" do
      kase.status = :in_progress
      expect(kase).to be_status_in_progress
      expect(kase).not_to be_status_not_started
      expect(kase).not_to be_archived
    end

    it "correctly identifies completed status" do
      kase.status = :completed
      expect(kase).to be_status_completed
      expect(kase).not_to be_status_not_started
      expect(kase).not_to be_status_in_progress
    end
  end

  describe "#editable?" do
    it "returns true for not_started cases" do
      kase.status = :not_started
      expect(kase).to be_editable
    end

    it "returns true for in_progress cases" do
      kase.status = :in_progress
      expect(kase).to be_editable
    end

    it "returns false for archived cases" do
      kase.archived_at = Time.current
      expect(kase).not_to be_editable
    end

    it "returns false for completed cases" do
      kase.status = :completed
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

  describe "status helpers" do
    let(:case_instance) { create(:case) }

    describe "#started?" do
      it "returns false when not started" do
        case_instance.status = :not_started
        expect(case_instance).not_to be_started
      end

      it "returns true when in progress" do
        case_instance.status = :in_progress
        expect(case_instance).to be_started
      end
    end

    describe "#completed?" do
      it "returns true when completed" do
        case_instance.status = :completed
        expect(case_instance).to be_completed
      end

      it "returns false when not completed" do
        case_instance.status = :in_progress
        expect(case_instance).not_to be_completed
      end
    end

    describe "#can_submit?" do
      it "returns true when in progress" do
        case_instance.status = :in_progress
        expect(case_instance).to be_can_submit
      end

      it "returns false when not in progress" do
        case_instance.status = :not_started
        expect(case_instance).not_to be_can_submit
      end
    end

    describe "#can_review?" do
      it "returns true when submitted" do
        case_instance.status = :submitted
        expect(case_instance).to be_can_review
      end

      it "returns false when not submitted" do
        case_instance.status = :in_progress
        expect(case_instance).not_to be_can_review
      end
    end
  end

  describe "status transitions" do
    let(:case_instance) { create(:case, status: :not_started) }

    describe "#start!" do
      context "when case is not started" do
        it "transitions to in_progress and sets published_at" do
          freeze_time do
            expect(case_instance.start!).to be true
            expect(case_instance.status).to eq("in_progress")
            expect(case_instance.published_at).to eq(Time.current)
          end
        end
      end

      context "when case is already started" do
        it "returns false and doesn't change status" do
          case_instance.update!(status: :in_progress)
          expect(case_instance.start!).to be false
          expect(case_instance.status).to eq("in_progress")
        end
      end
    end

    describe "#submit!" do
      context "when case is in progress" do
        it "transitions to submitted" do
          case_instance.update!(status: :in_progress)
          expect(case_instance.submit!).to be true
          expect(case_instance.status).to eq("submitted")
        end
      end

      context "when case is not in progress" do
        it "returns false and doesn't change status" do
          expect(case_instance.submit!).to be false
          expect(case_instance.status).to eq("not_started")
        end
      end
    end

    describe "#complete!" do
      context "when case is reviewed" do
        it "transitions to completed" do
          case_instance.update!(status: :reviewed)
          expect(case_instance.complete!).to be true
          expect(case_instance.status).to eq("completed")
        end
      end

      context "when case is not reviewed" do
        it "returns false and doesn't change status" do
          case_instance.update!(status: :submitted)
          expect(case_instance.complete!).to be false
          expect(case_instance.status).to eq("submitted")
        end
      end
    end
  end

  describe "status helper methods" do
    let(:case_instance) { create(:case) }

    describe "#editable? (detailed)" do
      it "returns true for not_started cases that are not archived" do
        case_instance.update!(status: :not_started, archived_at: nil)
        expect(case_instance).to be_editable
      end

      it "returns true for in_progress cases that are not archived" do
        case_instance.update!(status: :in_progress, archived_at: nil)
        expect(case_instance).to be_editable
      end

      it "returns false for archived cases" do
        case_instance.update!(status: :not_started, archived_at: Time.current)
        expect(case_instance).not_to be_editable
      end

      it "returns false for submitted cases" do
        case_instance.update!(status: :submitted)
        expect(case_instance).not_to be_editable
      end

      it "returns false for reviewed cases" do
        case_instance.update!(status: :reviewed)
        expect(case_instance).not_to be_editable
      end

      it "returns false for completed cases" do
        case_instance.update!(status: :completed)
        expect(case_instance).not_to be_editable
      end
    end
  end

  describe "soft deletion" do
    let(:case_instance) { create(:case) }

    it "can be soft deleted" do
      expect { case_instance.soft_delete }.to change(case_instance, :deleted_at).from(nil)
    end

    it "can be restored" do
      case_instance.soft_delete
      expect { case_instance.restore }.to change(case_instance, :deleted_at).to(nil)
    end
  end
end
