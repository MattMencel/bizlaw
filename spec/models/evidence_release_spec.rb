require "rails_helper"

RSpec.describe EvidenceRelease, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:simulation) }
    it { is_expected.to belong_to(:document) }
    it { is_expected.to belong_to(:requesting_team).class_name("Team").optional }
    it { is_expected.to delegate_method(:case).to(:simulation) }
  end

  describe "validations" do
    subject { build(:evidence_release) }

    it { is_expected.to validate_presence_of(:release_round) }
    it { is_expected.to validate_presence_of(:evidence_type) }
    it { is_expected.to validate_presence_of(:impact_description) }
    it { is_expected.to validate_numericality_of(:release_round).is_greater_than(0) }
    it { is_expected.to validate_inclusion_of(:evidence_type).in_array(EvidenceRelease::EVIDENCE_TYPES) }

    context "when auto_release is true" do
      subject { build(:evidence_release, auto_release: true) }

      it { is_expected.to validate_presence_of(:scheduled_release_at) }
    end

    context "when auto_release is false" do
      subject { build(:evidence_release, auto_release: false) }

      it { is_expected.to_not validate_presence_of(:scheduled_release_at) }
    end

    describe "#release_round_within_simulation_bounds" do
      let(:simulation) { create(:simulation, total_rounds: 3) }

      it "is valid when release_round is within bounds" do
        evidence_release = build(:evidence_release, simulation: simulation, release_round: 2)
        expect(evidence_release).to be_valid
      end

      it "is invalid when release_round exceeds total_rounds" do
        evidence_release = build(:evidence_release, simulation: simulation, release_round: 5)
        expect(evidence_release).to be_invalid
        expect(evidence_release.errors[:release_round]).to include("cannot exceed simulation total rounds")
      end
    end

    describe "#document_is_case_material" do
      let(:case_obj) { create(:case) }
      let(:simulation) { create(:simulation, case: case_obj) }

      context "with a valid case material document" do
        let(:document) { create(:document, documentable: case_obj, document_type: "assignment") }

        it "is valid" do
          evidence_release = build(:evidence_release, simulation: simulation, document: document)
          expect(evidence_release).to be_valid
        end
      end

      context "with a document not associated with the case" do
        let(:other_case) { create(:case) }
        let(:document) { create(:document, documentable: other_case, document_type: "assignment") }

        it "is invalid" do
          evidence_release = build(:evidence_release, simulation: simulation, document: document)
          expect(evidence_release).to be_invalid
          expect(evidence_release.errors[:document]).to include("must be a case material for this simulation's case")
        end
      end
    end

    describe "#requesting_team_in_case" do
      let(:case_obj) { create(:case) }
      let(:simulation) { create(:simulation, case: case_obj) }
      let(:team) { create(:team) }

      context "when team is assigned to the case" do
        before { create(:case_team, case: case_obj, team: team) }

        it "is valid" do
          evidence_release = build(:evidence_release, :team_requested, simulation: simulation, requesting_team: team)
          expect(evidence_release).to be_valid
        end
      end

      context "when team is not assigned to the case" do
        it "is invalid" do
          evidence_release = build(:evidence_release, :team_requested, simulation: simulation, requesting_team: team)
          expect(evidence_release).to be_invalid
          expect(evidence_release.errors[:requesting_team]).to include("must be assigned to this case")
        end
      end
    end
  end

  describe "evidence types" do
    it "defines all expected evidence types" do
      expected_types = %w[
        witness_statement expert_report company_document communication_record
        financial_document policy_document surveillance_footage additional_testimony
        settlement_history precedent_case medical_record performance_review
      ]
      expect(EvidenceRelease::EVIDENCE_TYPES).to match_array(expected_types)
    end
  end

  describe "scopes" do
    let!(:round_1_release) { create(:evidence_release, release_round: 1) }
    let!(:round_2_release) { create(:evidence_release, :round_2) }
    let!(:pending_release) { create(:evidence_release, released_at: nil) }
    let!(:released_evidence) { create(:evidence_release, :released) }
    let!(:auto_release) { create(:evidence_release, auto_release: true) }
    let!(:team_request) { create(:evidence_release, :team_requested) }
    let!(:overdue_release) { create(:evidence_release, :overdue) }

    describe ".scheduled_for_round" do
      it "returns releases for specified round" do
        expect(EvidenceRelease.scheduled_for_round(1)).to include(round_1_release)
        expect(EvidenceRelease.scheduled_for_round(1)).not_to include(round_2_release)
      end
    end

    describe ".pending_release" do
      it "returns unreleased evidence" do
        expect(EvidenceRelease.pending_release).to include(pending_release)
        expect(EvidenceRelease.pending_release).not_to include(released_evidence)
      end
    end

    describe ".released" do
      it "returns released evidence" do
        expect(EvidenceRelease.released).to include(released_evidence)
        expect(EvidenceRelease.released).not_to include(pending_release)
      end
    end

    describe ".auto_releases" do
      it "returns automatic releases" do
        expect(EvidenceRelease.auto_releases).to include(auto_release)
        expect(EvidenceRelease.auto_releases).not_to include(team_request)
      end
    end

    describe ".team_requests" do
      it "returns team-requested releases" do
        expect(EvidenceRelease.team_requests).to include(team_request)
        expect(EvidenceRelease.team_requests).not_to include(auto_release)
      end
    end

    describe ".ready_for_release" do
      it "returns releases scheduled for release" do
        expect(EvidenceRelease.ready_for_release).to include(overdue_release)
        expect(EvidenceRelease.ready_for_release).not_to include(round_2_release)
      end
    end
  end

  describe "instance methods" do
    describe "#released?" do
      it "returns true when released_at is present" do
        evidence_release = create(:evidence_release, :released)
        expect(evidence_release.released?).to be true
      end

      it "returns false when released_at is nil" do
        evidence_release = create(:evidence_release, released_at: nil)
        expect(evidence_release.released?).to be false
      end
    end

    describe "#ready_for_release?" do
      context "when already released" do
        it "returns false" do
          evidence_release = create(:evidence_release, :released)
          expect(evidence_release.ready_for_release?).to be false
        end
      end

      context "for team requests" do
        it "returns true when approved" do
          evidence_release = create(:evidence_release, :approved)
          expect(evidence_release.ready_for_release?).to be true
        end

        it "returns false when not approved" do
          evidence_release = create(:evidence_release, :team_requested)
          expect(evidence_release.ready_for_release?).to be false
        end
      end

      context "for auto releases" do
        it "returns true when scheduled time has passed" do
          evidence_release = create(:evidence_release, :overdue)
          expect(evidence_release.ready_for_release?).to be true
        end

        it "returns false when scheduled time is in future" do
          evidence_release = create(:evidence_release, scheduled_release_at: 1.week.from_now)
          expect(evidence_release.ready_for_release?).to be false
        end
      end
    end

    describe "#approved_for_release?" do
      it "returns true when team request is approved" do
        evidence_release = create(:evidence_release, :approved)
        expect(evidence_release.approved_for_release?).to be true
      end

      it "returns false when team request is not approved" do
        evidence_release = create(:evidence_release, :team_requested)
        expect(evidence_release.approved_for_release?).to be false
      end

      it "returns false for auto releases" do
        evidence_release = create(:evidence_release, auto_release: true)
        expect(evidence_release.approved_for_release?).to be false
      end
    end

    describe "#release!" do
      let(:simulation) { create(:simulation, current_round: 1) }
      let(:document) { create(:document, access_level: "instructor_only") }
      let(:evidence_release) { create(:evidence_release, simulation: simulation, document: document) }

      context "when ready for release" do
        before { allow(evidence_release).to receive(:ready_for_release?).and_return(true) }

        it "releases the evidence successfully" do
          expect { evidence_release.release! }.to change { evidence_release.reload.released_at }.from(nil)
        end

        it "updates document access" do
          evidence_release.release!
          expect(document.reload.access_level).to eq("case_teams")
        end

        it "creates a simulation event" do
          expect { evidence_release.release! }.to change { simulation.simulation_events.count }.by(1)
        end

        it "returns true" do
          expect(evidence_release.release!).to be true
        end
      end

      context "when not ready for release" do
        before { allow(evidence_release).to receive(:ready_for_release?).and_return(false) }

        it "does not release the evidence" do
          expect { evidence_release.release! }.not_to change { evidence_release.released_at }
        end

        it "returns false" do
          expect(evidence_release.release!).to be false
        end
      end

      context "when an error occurs" do
        before do
          allow(evidence_release).to receive(:ready_for_release?).and_return(true)
          allow(evidence_release).to receive(:update!).and_raise(StandardError.new("Database error"))
        end

        it "returns false and logs error" do
          expect(Rails.logger).to receive(:error).with(/Failed to release evidence/)
          expect(evidence_release.release!).to be false
        end
      end
    end
  end

  describe "class methods" do
    describe ".schedule_automatic_release" do
      let(:simulation) { create(:simulation, start_date: 1.week.ago) }
      let(:document) { create(:document) }

      it "creates an automatic release" do
        evidence_release = EvidenceRelease.schedule_automatic_release(
          simulation,
          document,
          2,
          "expert_report",
          "Critical expert analysis"
        )

        expect(evidence_release).to be_persisted
        expect(evidence_release.auto_release).to be true
        expect(evidence_release.team_requested).to be false
        expect(evidence_release.release_round).to eq(2)
        expect(evidence_release.evidence_type).to eq("expert_report")
        expect(evidence_release.scheduled_release_at).to be_within(1.minute).of(simulation.start_date + 14.days)
      end
    end

    describe ".create_team_request" do
      let(:simulation) { create(:simulation, current_round: 2) }
      let(:document) { create(:document) }
      let(:team) { create(:team) }

      it "creates a team request" do
        evidence_release = EvidenceRelease.create_team_request(
          simulation,
          document,
          team,
          "financial_document",
          "Need financial records for damages calculation"
        )

        expect(evidence_release).to be_persisted
        expect(evidence_release.team_requested).to be true
        expect(evidence_release.auto_release).to be false
        expect(evidence_release.requesting_team).to eq(team)
        expect(evidence_release.release_round).to eq(2)
        expect(evidence_release.evidence_type).to eq("financial_document")
        expect(evidence_release.release_conditions["request_justification"]).to eq("Need financial records for damages calculation")
      end
    end
  end

  describe "concerns" do
    it "includes HasUuid" do
      evidence_release = create(:evidence_release)
      expect(evidence_release.id).to be_a(String)
      expect(evidence_release.id.length).to eq(36) # UUID format
    end

    it "includes SoftDeletable" do
      evidence_release = create(:evidence_release)
      evidence_release.destroy
      expect(evidence_release.reload.deleted_at).to be_present
    end

    it "includes HasTimestamps" do
      evidence_release = create(:evidence_release)
      expect(evidence_release.created_at).to be_present
      expect(evidence_release.updated_at).to be_present
    end
  end
end
