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
    it { is_expected.to have_many(:simulations).dependent(:destroy) }
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
    it "defines status enum values" do
      expect(Case.statuses.keys).to contain_exactly("not_started", "in_progress", "submitted", "reviewed", "completed")
    end

    it "defines difficulty_level enum values" do
      expect(Case.difficulty_levels.keys).to contain_exactly("beginner", "intermediate", "advanced")
    end

    it "defines case_type enum values" do
      expect(Case.case_types.keys).to contain_exactly("sexual_harassment", "discrimination", "wrongful_termination", "contract_dispute", "intellectual_property")
    end
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
      let(:course) { create(:course) }
      let!(:old_case) { create(:case, created_at: 2.days.ago, course: course) }
      let!(:new_case) { create(:case, created_at: 1.day.ago, course: course) }

      it "orders cases by creation date descending" do
        cases_from_course = described_class.where(course: course).recent_first.to_a
        expect(cases_from_course).to eq([new_case, old_case])
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
        kase = build(:case, created_by: user, course: create(:course))
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

  describe "deletion business rules" do
    let(:instructor) { create(:user, :instructor) }
    let(:course) { create(:course, instructor: instructor) }
    let(:student1) { create(:user, :student) }
    let(:student2) { create(:user, :student) }

    describe "#can_be_deleted?" do
      context "when case is in not_started status" do
        let(:case_instance) { create(:case, status: :not_started, course: course, created_by: instructor) }

        context "with no teams assigned" do
          it "returns true" do
            expect(case_instance.can_be_deleted?).to be true
          end
        end

        context "with teams that have no student members" do
          let(:instructor_team) { create(:team, course: course, owner: instructor) }

          before do
            create(:case_team, case: case_instance, team: instructor_team, role: :plaintiff)
          end

          it "returns true" do
            expect(case_instance.can_be_deleted?).to be true
          end
        end

        context "with teams that have student members" do
          let(:student_team) { create(:team, course: course, owner: student1) }

          before do
            create(:team_member, team: student_team, user: student2, role: :member)
            create(:case_team, case: case_instance, team: student_team, role: :plaintiff)
          end

          it "returns false" do
            expect(case_instance.can_be_deleted?).to be false
          end
        end

        context "with mixed teams (some with students, some without)" do
          let(:instructor_team) { create(:team, course: course, owner: instructor) }
          let(:student_team) { create(:team, course: course, owner: student1) }

          before do
            create(:team_member, team: student_team, user: student2, role: :member)
            create(:case_team, case: case_instance, team: instructor_team, role: :plaintiff)
            create(:case_team, case: case_instance, team: student_team, role: :defendant)
          end

          it "returns false when any team has student members" do
            expect(case_instance.can_be_deleted?).to be false
          end
        end
      end

      context "when case is not in not_started status" do
        let(:case_instance) { create(:case, status: :in_progress, course: course, created_by: instructor) }

        it "returns false for in_progress status" do
          expect(case_instance.can_be_deleted?).to be false
        end

        it "returns false for submitted status" do
          case_instance.update!(status: :submitted)
          expect(case_instance.can_be_deleted?).to be false
        end

        it "returns false for reviewed status" do
          case_instance.update!(status: :reviewed)
          expect(case_instance.can_be_deleted?).to be false
        end

        it "returns false for completed status" do
          case_instance.update!(status: :completed)
          expect(case_instance.can_be_deleted?).to be false
        end
      end
    end

    describe "#deletion_error_message" do
      let(:case_instance) { create(:case, course: course, created_by: instructor) }

      context "when case is not in not_started status" do
        before { case_instance.update!(status: :in_progress) }

        it "returns status error message" do
          expect(case_instance.deletion_error_message).to eq("Case can only be deleted when in 'Not Started' status")
        end
      end

      context "when case has teams with student members" do
        let(:student_team) { create(:team, course: course, owner: student1) }

        before do
          case_instance.update!(status: :not_started)
          create(:team_member, team: student_team, user: student2, role: :member)
          create(:case_team, case: case_instance, team: student_team, role: :plaintiff)
        end

        it "returns team error message" do
          expect(case_instance.deletion_error_message).to eq("Cannot delete case with teams that have student members")
        end
      end

      context "when case can be deleted" do
        before { case_instance.update!(status: :not_started) }

        it "returns nil" do
          expect(case_instance.deletion_error_message).to be_nil
        end
      end
    end
  end

  describe "multiple simulations support" do
    let(:case_instance) { create(:case) }
    let!(:simulation1) { create(:simulation, case: case_instance, status: :setup, created_at: 1.day.ago) }
    let!(:simulation2) {
      create(:simulation,
             case: case_instance,
             status: :active,
             created_at: 2.hours.ago,
             start_date: 3.hours.ago,
             plaintiff_min_acceptable: 100000,
             plaintiff_ideal: 200000,
             defendant_max_acceptable: 150000,
             defendant_ideal: 50000)
    }
    let!(:simulation3) {
      create(:simulation,
             case: case_instance,
             status: :completed,
             created_at: 1.hour.ago,
             start_date: 2.hours.ago,
             end_date: 30.minutes.ago,
             plaintiff_min_acceptable: 80000,
             plaintiff_ideal: 180000,
             defendant_max_acceptable: 140000,
             defendant_ideal: 40000)
    }

    describe "#active_simulation" do
      it "returns the first active simulation" do
        expect(case_instance.active_simulation).to eq(simulation2)
      end

      context "when no simulations are active" do
        before do
          simulation2.update!(status: :completed)
        end

        it "returns the most recent simulation" do
          expect(case_instance.active_simulation).to eq(simulation3)
        end
      end

      context "when there are no simulations" do
        let(:case_without_simulations) { create(:case) }

        it "returns nil" do
          expect(case_without_simulations.active_simulation).to be_nil
        end
      end
    end

    describe "#current_phase" do
      it "returns the phase from the active simulation" do
        expect(case_instance.current_phase).to eq(simulation2.current_phase)
      end

      context "when there is no active simulation" do
        let(:case_without_simulations) { create(:case) }

        it "returns default phase" do
          expect(case_without_simulations.current_phase).to eq("Preparation")
        end
      end
    end

    describe "#current_round" do
      it "returns the round from the active simulation" do
        expect(case_instance.current_round).to eq(simulation2.current_round)
      end

      context "when there is no active simulation" do
        let(:case_without_simulations) { create(:case) }

        it "returns default round" do
          expect(case_without_simulations.current_round).to eq(1)
        end
      end
    end

    describe "#total_rounds" do
      it "returns the total rounds from the active simulation" do
        expect(case_instance.total_rounds).to eq(simulation2.total_rounds)
      end

      context "when there is no active simulation" do
        let(:case_without_simulations) { create(:case) }

        it "returns default total rounds" do
          expect(case_without_simulations.total_rounds).to eq(6)
        end
      end
    end
  end
end
