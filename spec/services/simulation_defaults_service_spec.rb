# frozen_string_literal: true

require "rails_helper"

RSpec.describe SimulationDefaultsService, type: :service do
  let(:case_record) { create(:case, case_type: :sexual_harassment) }
  let(:service) { described_class.new(case_record) }

  describe "#financial_defaults" do
    context "with sexual harassment case" do
      it "returns correct financial parameters" do
        defaults = service.financial_defaults

        expect(defaults[:plaintiff_min_acceptable]).to eq(150_000)
        expect(defaults[:plaintiff_ideal]).to eq(300_000)
        expect(defaults[:defendant_max_acceptable]).to eq(250_000)
        expect(defaults[:defendant_ideal]).to eq(75_000)
        expect(defaults[:total_rounds]).to eq(6)
      end
    end

    context "with contract dispute case" do
      let(:case_record) { create(:case, case_type: :contract_dispute) }

      it "returns correct financial parameters" do
        defaults = service.financial_defaults

        expect(defaults[:plaintiff_min_acceptable]).to eq(85_000)
        expect(defaults[:plaintiff_ideal]).to eq(175_000)
        expect(defaults[:defendant_max_acceptable]).to eq(125_000)
        expect(defaults[:defendant_ideal]).to eq(35_000)
        expect(defaults[:total_rounds]).to eq(6)
      end
    end

    context "with discrimination case" do
      let(:case_record) { create(:case, case_type: :discrimination) }

      it "returns correct financial parameters" do
        defaults = service.financial_defaults

        expect(defaults[:plaintiff_min_acceptable]).to eq(200_000)
        expect(defaults[:plaintiff_ideal]).to eq(450_000)
        expect(defaults[:defendant_max_acceptable]).to eq(350_000)
        expect(defaults[:defendant_ideal]).to eq(125_000)
        expect(defaults[:total_rounds]).to eq(6)
      end
    end

    context "with intellectual property case" do
      let(:case_record) { create(:case, case_type: :intellectual_property) }

      it "returns correct financial parameters" do
        defaults = service.financial_defaults

        expect(defaults[:plaintiff_min_acceptable]).to eq(2_500_000)
        expect(defaults[:plaintiff_ideal]).to eq(8_000_000)
        expect(defaults[:defendant_max_acceptable]).to eq(5_500_000)
        expect(defaults[:defendant_ideal]).to eq(1_200_000)
        expect(defaults[:total_rounds]).to eq(8)
      end
    end

    context "with wrongful termination case" do
      let(:case_record) { create(:case, case_type: :wrongful_termination) }

      it "returns correct financial parameters" do
        defaults = service.financial_defaults

        expect(defaults[:plaintiff_min_acceptable]).to eq(125_000)
        expect(defaults[:plaintiff_ideal]).to eq(275_000)
        expect(defaults[:defendant_max_acceptable]).to eq(200_000)
        expect(defaults[:defendant_ideal]).to eq(65_000)
        expect(defaults[:total_rounds]).to eq(6)
      end
    end

    context "with unknown case type" do
      let(:case_record) { build(:case, case_type: nil) }

      it "returns default financial parameters" do
        defaults = service.financial_defaults

        expect(defaults[:plaintiff_min_acceptable]).to eq(150_000)
        expect(defaults[:plaintiff_ideal]).to eq(300_000)
        expect(defaults[:defendant_max_acceptable]).to eq(250_000)
        expect(defaults[:defendant_ideal]).to eq(75_000)
        expect(defaults[:total_rounds]).to eq(6)
      end
    end
  end

  describe "#randomized_financial_defaults" do
    it "generates parameters within expected ranges" do
      defaults = service.randomized_financial_defaults

      expect(defaults[:plaintiff_min_acceptable]).to be_between(75_000, 225_000)
      expect(defaults[:plaintiff_ideal]).to be_between(150_000, 450_000)
      expect(defaults[:defendant_max_acceptable]).to be_between(125_000, 375_000)
      expect(defaults[:defendant_ideal]).to be_between(37_500, 187_500)
    end

    it "maintains mathematical validity" do
      defaults = service.randomized_financial_defaults

      expect(defaults[:plaintiff_min_acceptable]).to be < defaults[:plaintiff_ideal]
      expect(defaults[:defendant_ideal]).to be < defaults[:defendant_max_acceptable]
      expect(defaults[:plaintiff_min_acceptable]).to be <= defaults[:defendant_max_acceptable]
    end

    it "generates different values on repeated calls" do
      defaults1 = service.randomized_financial_defaults
      defaults2 = service.randomized_financial_defaults

      expect(defaults1).not_to eq(defaults2)
    end

    context "with different case types" do
      let(:case_record) { create(:case, case_type: :intellectual_property) }

      it "scales ranges appropriately for high-value cases" do
        defaults = service.randomized_financial_defaults

        expect(defaults[:plaintiff_min_acceptable]).to be_between(1_250_000, 3_750_000)
        expect(defaults[:plaintiff_ideal]).to be_between(4_000_000, 12_000_000)
        expect(defaults[:defendant_max_acceptable]).to be_between(2_750_000, 8_250_000)
        expect(defaults[:defendant_ideal]).to be_between(600_000, 1_800_000)
      end
    end
  end

  describe "#default_teams" do
    # 72001a1 moved team creation onto Simulation#create_default_teams and left
    # find_or_create_team here as an unconditional `nil` stub, so default_teams
    # no longer builds anything. The five specs that used to cover team
    # find-or-create behaviour asserted the pre-72001a1 case_teams model and
    # could not pass against the current code; this pins what it actually does.
    # SimulationDefaultsService#find_or_create_team and #create_team_for_role
    # are both unreachable and want deleting separately.
    it "returns no teams, leaving creation to the simulation" do
      expect(service.default_teams).to eq(plaintiff_team: nil, defendant_team: nil)
    end

    it "creates the default teams when the simulation is created" do
      simulation = create(:simulation, case: case_record)

      expect(simulation.plaintiff_team.name).to eq("Plaintiff Team")
      expect(simulation.defendant_team.name).to eq("Defendant Team")
      expect(case_record.teams).to include(simulation.plaintiff_team, simulation.defendant_team)
    end
  end

  describe "#build_simulation_with_defaults" do
    it "creates simulation with financial defaults and teams" do
      simulation = service.build_simulation_with_defaults

      expect(simulation).to be_a(Simulation)
      expect(simulation.case).to eq(case_record)
      expect(simulation.plaintiff_min_acceptable).to eq(150_000)
      expect(simulation.plaintiff_ideal).to eq(300_000)
      expect(simulation.defendant_max_acceptable).to eq(250_000)
      expect(simulation.defendant_ideal).to eq(75_000)
      expect(simulation.total_rounds).to eq(6)
      expect(simulation.current_round).to eq(1)
      expect(simulation.status).to eq("setup")
      expect(simulation.pressure_escalation_rate).to eq("moderate")
    end

    it "gets its teams once saved" do
      # build_simulation_with_defaults returns an unsaved record; the default
      # teams come from Simulation's after_create, so there are none until save.
      simulation = service.build_simulation_with_defaults
      expect(simulation.plaintiff_team).to be_nil

      simulation.save!
      simulation.reload

      expect(simulation.plaintiff_team.name).to eq("Plaintiff Team")
      expect(simulation.defendant_team.name).to eq("Defendant Team")
    end

    it "includes default simulation config" do
      simulation = service.build_simulation_with_defaults
      config = simulation.simulation_config

      expect(config["client_mood_enabled"]).to eq("true")
      expect(config["pressure_escalation_enabled"]).to eq("true")
      expect(config["auto_round_advancement"]).to eq("false")
      expect(config["settlement_range_hints"]).to eq("false")
      expect(config["arbitration_threshold_rounds"]).to eq("5")
      expect(config["round_duration_hours"]).to eq("48")
    end
  end

  describe "#build_simulation_with_randomized_defaults" do
    it "creates simulation with randomized financial parameters" do
      simulation = service.build_simulation_with_randomized_defaults

      expect(simulation).to be_a(Simulation)
      expect(simulation.case).to eq(case_record)
      expect(simulation.plaintiff_min_acceptable).to be_between(75_000, 225_000)
      expect(simulation.plaintiff_ideal).to be_between(150_000, 450_000)
      expect(simulation.defendant_max_acceptable).to be_between(125_000, 375_000)
      expect(simulation.defendant_ideal).to be_between(37_500, 187_500)
    end

    it "maintains validity constraints" do
      simulation = service.build_simulation_with_randomized_defaults

      expect(simulation.plaintiff_min_acceptable).to be < simulation.plaintiff_ideal
      expect(simulation.defendant_ideal).to be < simulation.defendant_max_acceptable
      expect(simulation.plaintiff_min_acceptable).to be <= simulation.defendant_max_acceptable
    end

    it "generates different simulations on repeated calls" do
      sim1 = service.build_simulation_with_randomized_defaults
      sim2 = service.build_simulation_with_randomized_defaults

      params1 = [sim1.plaintiff_min_acceptable, sim1.plaintiff_ideal, sim1.defendant_max_acceptable, sim1.defendant_ideal]
      params2 = [sim2.plaintiff_min_acceptable, sim2.plaintiff_ideal, sim2.defendant_max_acceptable, sim2.defendant_ideal]

      expect(params1).not_to eq(params2)
    end
  end
end
