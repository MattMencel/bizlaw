# frozen_string_literal: true

require "rails_helper"

RSpec.describe Simulation, type: :model do
  subject(:simulation) { build(:simulation) }

  describe "associations" do
    it { is_expected.to belong_to(:case) }
    it { is_expected.to have_many(:negotiation_rounds).dependent(:destroy) }
    it { is_expected.to have_many(:settlement_offers).through(:negotiation_rounds) }
    it { is_expected.to have_many(:simulation_events).dependent(:destroy) }
    it { is_expected.to have_many(:performance_scores).dependent(:destroy) }
    it { is_expected.to have_many(:client_feedbacks).dependent(:destroy) }
    it { is_expected.to have_one(:arbitration_outcome).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:start_date) }
    it { is_expected.to validate_presence_of(:total_rounds) }
    it { is_expected.to validate_numericality_of(:total_rounds).is_greater_than(0).is_less_than_or_equal_to(10) }
    it { is_expected.to validate_presence_of(:current_round) }
    it { is_expected.to validate_numericality_of(:current_round).is_greater_than_or_equal_to(1) }
    it { is_expected.to validate_presence_of(:plaintiff_min_acceptable) }
    it { is_expected.to validate_numericality_of(:plaintiff_min_acceptable).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:plaintiff_ideal) }
    it { is_expected.to validate_numericality_of(:plaintiff_ideal).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:defendant_max_acceptable) }
    it { is_expected.to validate_numericality_of(:defendant_max_acceptable).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:defendant_ideal) }
    it { is_expected.to validate_numericality_of(:defendant_ideal).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_presence_of(:simulation_config) }

    describe "custom validations" do
      it "validates current_round_within_total_rounds" do
        simulation.current_round = 10
        simulation.total_rounds = 5
        expect(simulation).not_to be_valid
        expect(simulation.errors[:current_round]).to include("cannot be greater than total rounds")
      end

      it "validates plaintiff_amounts_logical" do
        simulation.plaintiff_min_acceptable = 300000
        simulation.plaintiff_ideal = 200000
        expect(simulation).not_to be_valid
        expect(simulation.errors[:plaintiff_min_acceptable]).to include("cannot be greater than ideal amount")
      end

      it "validates defendant_amounts_logical" do
        simulation.defendant_ideal = 200000
        simulation.defendant_max_acceptable = 100000
        expect(simulation).not_to be_valid
        expect(simulation.errors[:defendant_ideal]).to include("cannot be greater than maximum acceptable amount")
      end
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(setup: "setup", active: "active", paused: "paused", completed: "completed", arbitration: "arbitration").with_prefix(:status) }
    it { is_expected.to define_enum_for(:pressure_escalation_rate).with_values(low: "low", moderate: "moderate", high: "high").with_prefix(:pressure) }
  end

  describe "scopes" do
    let!(:active_simulation) { create(:simulation, status: :active) }
    let!(:completed_simulation) { create(:simulation, status: :completed) }
    let!(:setup_simulation) { create(:simulation, status: :setup) }

    describe ".active_simulations" do
      it "returns active and paused simulations" do
        paused_simulation = create(:simulation, status: :paused)
        expect(Simulation.active_simulations).to contain_exactly(active_simulation, paused_simulation)
      end
    end

    describe ".completed_simulations" do
      it "returns completed and arbitration simulations" do
        arbitration_simulation = create(:simulation, status: :arbitration)
        expect(Simulation.completed_simulations).to contain_exactly(completed_simulation, arbitration_simulation)
      end
    end
  end

  describe "instance methods" do
    describe "#active?" do
      it "returns true for active status" do
        simulation.status = :active
        expect(simulation).to be_active
      end

      it "returns true for paused status" do
        simulation.status = :paused
        expect(simulation).to be_active
      end

      it "returns false for other statuses" do
        simulation.status = :setup
        expect(simulation).not_to be_active
      end
    end

    describe "#can_advance_round?" do
      let!(:simulation) { create(:simulation, status: :active, current_round: 2, total_rounds: 6) }

      it "returns false if simulation is not active" do
        simulation.update!(status: :setup)
        expect(simulation.can_advance_round?).to be false
      end

      it "returns false if current round is at maximum" do
        simulation.update!(current_round: 6)
        expect(simulation.can_advance_round?).to be false
      end

      it "returns true when conditions are met" do
        create(:negotiation_round, simulation: simulation, round_number: 2, status: :completed)
        expect(simulation.can_advance_round?).to be true
      end
    end

    describe "#next_round!" do
      let!(:simulation) { create(:simulation, status: :active, current_round: 2, total_rounds: 6) }

      it "advances to next round when possible" do
        create(:negotiation_round, simulation: simulation, round_number: 2, status: :completed)
        expect { simulation.next_round! }.to change { simulation.current_round }.from(2).to(3)
      end

      it "returns false when cannot advance" do
        expect(simulation.next_round!).to be false
      end
    end

    describe "#complete!" do
      it "sets status to completed and end_date" do
        freeze_time do
          simulation.complete!
          expect(simulation.status).to eq("completed")
          expect(simulation.end_date).to eq(Time.current)
        end
      end
    end

    describe "#trigger_arbitration!" do
      it "sets status to arbitration and end_date" do
        freeze_time do
          simulation.trigger_arbitration!
          expect(simulation.status).to eq("arbitration")
          expect(simulation.end_date).to eq(Time.current)
        end
      end
    end

    describe "#start!" do
      let(:simulation) { create(:simulation, status: :setup) }

      it "transitions from setup to active" do
        expect { simulation.start! }.to change { simulation.status }.from("setup").to("active")
      end

      it "sets start_date when starting" do
        freeze_time do
          simulation.start!
          expect(simulation.start_date).to eq(Time.current)
        end
      end

      context "when already active" do
        let(:simulation) { create(:simulation, status: :active) }

        it "returns false and doesn't change status" do
          original_status = simulation.status
          expect(simulation.start!).to be false
          expect(simulation.status).to eq(original_status)
        end
      end
    end

    describe "#pause!" do
      let(:simulation) { create(:simulation, status: :active) }

      it "transitions from active to paused" do
        expect { simulation.pause! }.to change { simulation.status }.from("active").to("paused")
      end

      context "when not active" do
        let(:simulation) { create(:simulation, status: :setup) }

        it "returns false and doesn't change status" do
          expect(simulation.pause!).to be false
          expect(simulation.status).to eq("setup")
        end
      end
    end

    describe "#resume!" do
      let(:simulation) { create(:simulation, status: :paused) }

      it "transitions from paused to active" do
        expect { simulation.resume! }.to change { simulation.status }.from("paused").to("active")
      end

      context "when not paused" do
        let(:simulation) { create(:simulation, status: :setup) }

        it "returns false and doesn't change status" do
          expect(simulation.resume!).to be false
          expect(simulation.status).to eq("setup")
        end
      end
    end
  end

  describe "default financial parameters" do
    let(:case_record) { create(:case, case_type: :sexual_harassment) }

    describe ".build_with_defaults" do
      it "creates simulation with case-type specific defaults" do
        simulation = Simulation.build_with_defaults(case_record)

        expect(simulation.plaintiff_min_acceptable).to eq(150_000)
        expect(simulation.plaintiff_ideal).to eq(300_000)
        expect(simulation.defendant_max_acceptable).to eq(250_000)
        expect(simulation.defendant_ideal).to eq(75_000)
      end

      it "uses default values for unknown case types" do
        case_record.update!(case_type: nil)
        simulation = Simulation.build_with_defaults(case_record)

        expect(simulation.plaintiff_min_acceptable).to eq(150_000)
        expect(simulation.plaintiff_ideal).to eq(300_000)
        expect(simulation.defendant_max_acceptable).to eq(250_000)
        expect(simulation.defendant_ideal).to eq(75_000)
      end

      it "sets default configuration values" do
        simulation = Simulation.build_with_defaults(case_record)

        expect(simulation.total_rounds).to eq(6)
        expect(simulation.current_round).to eq(1)
        expect(simulation.status).to eq("setup")
        expect(simulation.pressure_escalation_rate).to eq("moderate")
      end

      context "with different case types" do
        it "applies contract dispute defaults" do
          case_record.update!(case_type: :contract_dispute)
          simulation = Simulation.build_with_defaults(case_record)

          expect(simulation.plaintiff_min_acceptable).to eq(85_000)
          expect(simulation.plaintiff_ideal).to eq(175_000)
          expect(simulation.defendant_max_acceptable).to eq(125_000)
          expect(simulation.defendant_ideal).to eq(35_000)
        end

        it "applies discrimination defaults" do
          case_record.update!(case_type: :discrimination)
          simulation = Simulation.build_with_defaults(case_record)

          expect(simulation.plaintiff_min_acceptable).to eq(200_000)
          expect(simulation.plaintiff_ideal).to eq(450_000)
          expect(simulation.defendant_max_acceptable).to eq(350_000)
          expect(simulation.defendant_ideal).to eq(125_000)
        end

        it "applies intellectual property defaults" do
          case_record.update!(case_type: :intellectual_property)
          simulation = Simulation.build_with_defaults(case_record)

          expect(simulation.plaintiff_min_acceptable).to eq(2_500_000)
          expect(simulation.plaintiff_ideal).to eq(8_000_000)
          expect(simulation.defendant_max_acceptable).to eq(5_500_000)
          expect(simulation.defendant_ideal).to eq(1_200_000)
          expect(simulation.total_rounds).to eq(8)
        end

        it "applies wrongful termination defaults" do
          case_record.update!(case_type: :wrongful_termination)
          simulation = Simulation.build_with_defaults(case_record)

          expect(simulation.plaintiff_min_acceptable).to eq(125_000)
          expect(simulation.plaintiff_ideal).to eq(275_000)
          expect(simulation.defendant_max_acceptable).to eq(200_000)
          expect(simulation.defendant_ideal).to eq(65_000)
        end
      end
    end

    describe ".randomize_financial_parameters" do
      it "generates randomized parameters within realistic ranges" do
        simulation = Simulation.build_with_defaults(case_record)
        original_params = [
          simulation.plaintiff_min_acceptable,
          simulation.plaintiff_ideal,
          simulation.defendant_max_acceptable,
          simulation.defendant_ideal
        ]

        simulation.randomize_financial_parameters!

        new_params = [
          simulation.plaintiff_min_acceptable,
          simulation.plaintiff_ideal,
          simulation.defendant_max_acceptable,
          simulation.defendant_ideal
        ]

        expect(new_params).not_to eq(original_params)
        expect(simulation.plaintiff_min_acceptable).to be < simulation.plaintiff_ideal
        expect(simulation.defendant_ideal).to be < simulation.defendant_max_acceptable
        expect(simulation.plaintiff_min_acceptable).to be <= simulation.defendant_max_acceptable
      end

      it "maintains mathematical validity" do
        simulation = Simulation.build_with_defaults(case_record)
        simulation.randomize_financial_parameters!

        expect(simulation).to be_valid
      end

      it "generates different values on multiple calls" do
        simulation1 = Simulation.build_with_defaults(case_record)
        simulation2 = Simulation.build_with_defaults(case_record)

        simulation1.randomize_financial_parameters!
        simulation2.randomize_financial_parameters!

        params1 = [simulation1.plaintiff_min_acceptable, simulation1.plaintiff_ideal, simulation1.defendant_max_acceptable, simulation1.defendant_ideal]
        params2 = [simulation2.plaintiff_min_acceptable, simulation2.plaintiff_ideal, simulation2.defendant_max_acceptable, simulation2.defendant_ideal]

        expect(params1).not_to eq(params2)
      end
    end
  end

  describe "default team creation" do
    let(:case_record) { create(:case) }
    let(:course) { case_record.course }

    describe ".create_with_defaults" do
      it "creates empty plaintiff and defendant teams" do
        simulation = Simulation.create_with_defaults(case_record: case_record)

        expect(simulation.plaintiff_team).to be_present
        expect(simulation.defendant_team).to be_present
        expect(simulation.plaintiff_team.name).to eq("Plaintiff Team")
        expect(simulation.defendant_team.name).to eq("Defendant Team")
        expect(simulation.plaintiff_team.users).to be_empty
        expect(simulation.defendant_team.users).to be_empty
      end

      it "uses existing case teams if available" do
        plaintiff_team = create(:team, name: "Existing Plaintiff", course: course)
        defendant_team = create(:team, name: "Existing Defendant", course: course)
        create(:case_team, case: case_record, team: plaintiff_team, role: :plaintiff)
        create(:case_team, case: case_record, team: defendant_team, role: :defendant)

        simulation = Simulation.create_with_defaults(case_record: case_record)

        expect(simulation.plaintiff_team).to eq(plaintiff_team)
        expect(simulation.defendant_team).to eq(defendant_team)
      end

      it "creates missing teams when only one exists" do
        existing_team = create(:team, name: "Existing Plaintiff", course: course)
        create(:case_team, case: case_record, team: existing_team, role: :plaintiff)

        simulation = Simulation.create_with_defaults(case_record: case_record)

        expect(simulation.plaintiff_team).to eq(existing_team)
        expect(simulation.defendant_team).to be_present
        expect(simulation.defendant_team.name).to eq("Defendant Team")
      end

      it "associates teams with the case" do
        simulation = Simulation.create_with_defaults(case_record: case_record)

        expect(case_record.case_teams.count).to eq(2)
        expect(case_record.case_teams.plaintiff.first.team).to eq(simulation.plaintiff_team)
        expect(case_record.case_teams.defendant.first.team).to eq(simulation.defendant_team)
      end
    end
  end

  describe "status predicates" do
    describe "#active?" do
      it "returns true for active status" do
        simulation.status = :active
        expect(simulation).to be_active
      end

      it "returns true for paused status" do
        simulation.status = :paused
        expect(simulation).to be_active
      end

      it "returns false for setup status" do
        simulation.status = :setup
        expect(simulation).not_to be_active
      end

      it "returns false for completed status" do
        simulation.status = :completed
        expect(simulation).not_to be_active
      end

      it "returns false for arbitration status" do
        simulation.status = :arbitration
        expect(simulation).not_to be_active
      end
    end

    describe "#completed?" do
      it "returns true for completed status" do
        simulation.status = :completed
        expect(simulation).to be_completed
      end

      it "returns true for arbitration status" do
        simulation.status = :arbitration
        expect(simulation).to be_completed
      end

      it "returns false for active status" do
        simulation.status = :active
        expect(simulation).not_to be_completed
      end

      it "returns false for setup status" do
        simulation.status = :setup
        expect(simulation).not_to be_completed
      end
    end

    describe "#running?" do
      it "returns true for active status" do
        simulation.status = :active
        expect(simulation).to be_running
      end

      it "returns false for paused status" do
        simulation.status = :paused
        expect(simulation).not_to be_running
      end

      it "returns false for other statuses" do
        [:setup, :completed, :arbitration].each do |status|
          simulation.status = status
          expect(simulation).not_to be_running
        end
      end
    end
  end
end
