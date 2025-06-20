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
