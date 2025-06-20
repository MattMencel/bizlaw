# frozen_string_literal: true

require "rails_helper"

RSpec.describe SimulationOrchestrationService, type: :service do
  let(:organization) { create(:organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:course) { create(:course, instructor: instructor, organization: organization) }
  let(:case_instance) { create(:case, course: course, created_by: instructor) }

  # Create teams
  let(:plaintiff_team) { create(:team, course: course) }
  let(:defendant_team) { create(:team, course: course) }

  # Create simulation with proper team assignments
  let(:simulation) do
    create(:simulation,
      case: case_instance,
      status: :setup,
      plaintiff_team: plaintiff_team,
      defendant_team: defendant_team,
      plaintiff_min_acceptable: 100000,
      plaintiff_ideal: 300000,
      defendant_ideal: 50000,
      defendant_max_acceptable: 200000)
  end

  subject(:service) { described_class.new(simulation) }

  describe "#initialize" do
    it "sets the simulation" do
      expect(service.simulation).to eq(simulation)
    end
  end

  describe "#start_simulation!" do
    context "when simulation is ready to start" do
      it "starts the simulation successfully" do
        freeze_time do
          result = service.start_simulation!

          expect(result[:simulation_started]).to be true
          expect(result[:start_time]).to eq(Time.current)
          expect(simulation.reload.status).to eq("active")
          expect(simulation.start_date).to eq(Time.current)
        end
      end

      it "creates initial negotiation round" do
        expect { service.start_simulation! }.to change { simulation.negotiation_rounds.count }.by(1)

        initial_round = simulation.negotiation_rounds.first
        expect(initial_round.round_number).to eq(1)
        expect(initial_round.status).to eq("active")
        expect(initial_round.deadline).to be_within(1.minute).of(48.hours.from_now)
      end

      it "schedules future simulation events" do
        allow_any_instance_of(SimulationEventOrchestrator).to receive(:schedule_future_events!)

        service.start_simulation!

        expect_any_instance_of(SimulationEventOrchestrator).to have_received(:schedule_future_events!).with(2, 24)
      end

      it "returns the initial round in results" do
        result = service.start_simulation!
        initial_round = simulation.negotiation_rounds.first

        expect(result[:initial_round]).to eq(initial_round)
      end
    end

    context "when simulation validation fails" do
      context "missing plaintiff minimum acceptable amount" do
        before { simulation.update!(plaintiff_min_acceptable: nil) }

        it "raises error with validation message" do
          expect { service.start_simulation! }.to raise_error(StandardError, /Plaintiff minimum acceptable amount must be set/)
        end
      end

      context "missing defendant maximum acceptable amount" do
        before { simulation.update!(defendant_max_acceptable: nil) }

        it "raises error with validation message" do
          expect { service.start_simulation! }.to raise_error(StandardError, /Defendant maximum acceptable amount must be set/)
        end
      end

      context "missing plaintiff team" do
        before { simulation.update!(plaintiff_team: nil) }

        it "raises error with validation message" do
          expect { service.start_simulation! }.to raise_error(StandardError, /Both plaintiff and defendant teams must be assigned/)
        end
      end

      context "missing defendant team" do
        before { simulation.update!(defendant_team: nil) }

        it "raises error with validation message" do
          expect { service.start_simulation! }.to raise_error(StandardError, /Both plaintiff and defendant teams must be assigned/)
        end
      end

      context "illogical plaintiff amounts" do
        before { simulation.update!(plaintiff_min_acceptable: 400000, plaintiff_ideal: 300000) }

        it "raises error with validation message" do
          expect { service.start_simulation! }.to raise_error(StandardError, /Plaintiff minimum cannot be greater than ideal/)
        end
      end

      context "illogical defendant amounts" do
        before { simulation.update!(defendant_ideal: 250000, defendant_max_acceptable: 200000) }

        it "raises error with validation message" do
          expect { service.start_simulation! }.to raise_error(StandardError, /Defendant ideal cannot be greater than maximum/)
        end
      end

      context "no overlap in acceptable ranges" do
        before do
          simulation.update!(
            plaintiff_min_acceptable: 300000,
            defendant_max_acceptable: 200000
          )
        end

        it "raises error with validation message" do
          expect { service.start_simulation! }.to raise_error(StandardError, /No overlap in acceptable settlement ranges/)
        end
      end
    end

    context "when simulation is already active" do
      before { simulation.update!(status: :active) }

      it "raises error" do
        expect { service.start_simulation! }.to raise_error(StandardError, /Simulation must be in setup status/)
      end
    end
  end

  describe "#validate_simulation_readiness" do
    context "when all validations pass" do
      it "returns empty errors array" do
        expect(service.send(:validate_simulation_readiness)).to be_empty
      end
    end

    context "when validations fail" do
      it "returns array of error messages" do
        simulation.update!(
          plaintiff_min_acceptable: nil,
          defendant_max_acceptable: nil,
          plaintiff_team: nil
        )

        errors = service.send(:validate_simulation_readiness)

        expect(errors).to include("Plaintiff minimum acceptable amount must be set")
        expect(errors).to include("Defendant maximum acceptable amount must be set")
        expect(errors).to include("Both plaintiff and defendant teams must be assigned")
      end
    end
  end

  describe "#pause_simulation!" do
    before { simulation.update!(status: :active) }

    it "pauses the simulation" do
      service.pause_simulation!
      expect(simulation.reload.status).to eq("paused")
    end

    it "pauses active rounds" do
      round = create(:negotiation_round, :active, simulation: simulation)

      service.pause_simulation!

      expect(round.reload.status).to eq("paused")
    end

    context "when simulation is not active" do
      before { simulation.update!(status: :setup) }

      it "raises error" do
        expect { service.pause_simulation! }.to raise_error(StandardError, /Simulation must be active to pause/)
      end
    end
  end

  describe "#resume_simulation!" do
    before { simulation.update!(status: :paused) }

    it "resumes the simulation" do
      service.resume_simulation!
      expect(simulation.reload.status).to eq("active")
    end

    it "resumes paused rounds" do
      round = create(:negotiation_round, simulation: simulation, status: :paused)

      service.resume_simulation!

      expect(round.reload.status).to eq("active")
    end

    context "when simulation is not paused" do
      before { simulation.update!(status: :active) }

      it "raises error" do
        expect { service.resume_simulation! }.to raise_error(StandardError, /Simulation must be paused to resume/)
      end
    end
  end

  describe "#complete_simulation!" do
    before { simulation.update!(status: :active) }

    it "completes the simulation" do
      freeze_time do
        service.complete_simulation!

        expect(simulation.reload.status).to eq("completed")
        expect(simulation.end_date).to eq(Time.current)
      end
    end

    it "completes active rounds" do
      round = create(:negotiation_round, :active, simulation: simulation)

      service.complete_simulation!

      expect(round.reload.status).to eq("completed")
    end

    it "creates simulation completion event" do
      expect { service.complete_simulation! }.to change { simulation.simulation_events.count }.by(1)

      event = simulation.simulation_events.last
      expect(event.event_type).to eq("simulation_completed")
    end
  end

  describe "#trigger_arbitration!" do
    before { simulation.update!(status: :active) }

    it "triggers arbitration" do
      freeze_time do
        service.trigger_arbitration!

        expect(simulation.reload.status).to eq("arbitration")
        expect(simulation.end_date).to eq(Time.current)
      end
    end

    it "creates arbitration event" do
      expect { service.trigger_arbitration! }.to change { simulation.simulation_events.count }.by(1)

      event = simulation.simulation_events.last
      expect(event.event_type).to eq("arbitration_triggered")
    end

    it "calculates arbitration outcome" do
      service.trigger_arbitration!

      expect(simulation.arbitration_outcome).to be_present
      expect(simulation.arbitration_outcome.award_amount).to be_present
    end
  end

  describe "#advance_round!" do
    let!(:current_round) { create(:negotiation_round, simulation: simulation, round_number: 1, status: :completed) }

    before { simulation.update!(status: :active, current_round: 1, total_rounds: 3) }

    it "advances to next round" do
      expect { service.advance_round! }.to change { simulation.current_round }.from(1).to(2)
    end

    it "creates new negotiation round" do
      expect { service.advance_round! }.to change { simulation.negotiation_rounds.count }.by(1)

      new_round = simulation.negotiation_rounds.last
      expect(new_round.round_number).to eq(2)
      expect(new_round.status).to eq("active")
    end

    it "creates round advancement event" do
      expect { service.advance_round! }.to change { simulation.simulation_events.count }.by(1)

      event = simulation.simulation_events.last
      expect(event.event_type).to eq("round_advanced")
    end

    context "when current round is not completed" do
      before { current_round.update!(status: :active) }

      it "raises error" do
        expect { service.advance_round! }.to raise_error(StandardError, /Current round must be completed/)
      end
    end

    context "when at maximum rounds" do
      before { simulation.update!(current_round: 3) }

      it "raises error" do
        expect { service.advance_round! }.to raise_error(StandardError, /Cannot advance beyond maximum rounds/)
      end
    end
  end

  describe "private methods" do
    describe "#create_initial_round" do
      it "creates round with correct attributes" do
        round = service.send(:create_initial_round)

        expect(round.simulation).to eq(simulation)
        expect(round.round_number).to eq(1)
        expect(round.status).to eq("active")
        expect(round.deadline).to be_within(1.minute).of(48.hours.from_now)
      end
    end

    describe "#update_simulation_status" do
      it "updates simulation to active with start date" do
        freeze_time do
          service.send(:update_simulation_status, :active)

          expect(simulation.reload.status).to eq("active")
          expect(simulation.start_date).to eq(Time.current)
        end
      end
    end

    describe "#schedule_simulation_events" do
      it "delegates to SimulationEventOrchestrator" do
        orchestrator = instance_double(SimulationEventOrchestrator)
        allow(SimulationEventOrchestrator).to receive(:new).with(simulation).and_return(orchestrator)
        expect(orchestrator).to receive(:schedule_future_events!).with(2, 24)

        service.send(:schedule_simulation_events, 2, 24)
      end
    end
  end
end
