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
    let(:course) { case_record.course }

    context "when no teams exist for the case" do
      it "creates new plaintiff and defendant teams" do
        teams = service.default_teams

        expect(teams[:plaintiff_team]).to be_a(Team)
        expect(teams[:defendant_team]).to be_a(Team)
        expect(teams[:plaintiff_team].name).to eq("Plaintiff Team")
        expect(teams[:defendant_team].name).to eq("Defendant Team")
        expect(teams[:plaintiff_team].course).to eq(course)
        expect(teams[:defendant_team].course).to eq(course)
      end

      it "creates case team associations" do
        teams = service.default_teams

        plaintiff_case_team = case_record.case_teams.find_by(role: :plaintiff)
        defendant_case_team = case_record.case_teams.find_by(role: :defendant)

        expect(plaintiff_case_team.team).to eq(teams[:plaintiff_team])
        expect(defendant_case_team.team).to eq(teams[:defendant_team])
      end
    end

    context "when teams already exist for the case" do
      let!(:existing_plaintiff) { create(:team, name: "Existing Plaintiff", course: course) }
      let!(:existing_defendant) { create(:team, name: "Existing Defendant", course: course) }

      before do
        create(:case_team, case: case_record, team: existing_plaintiff, role: :plaintiff)
        create(:case_team, case: case_record, team: existing_defendant, role: :defendant)
      end

      it "uses existing teams" do
        teams = service.default_teams

        expect(teams[:plaintiff_team]).to eq(existing_plaintiff)
        expect(teams[:defendant_team]).to eq(existing_defendant)
      end
    end

    context "when only plaintiff team exists" do
      let!(:existing_plaintiff) { create(:team, name: "Existing Plaintiff", course: course) }

      before do
        create(:case_team, case: case_record, team: existing_plaintiff, role: :plaintiff)
      end

      it "uses existing plaintiff and creates defendant team" do
        teams = service.default_teams

        expect(teams[:plaintiff_team]).to eq(existing_plaintiff)
        expect(teams[:defendant_team]).to be_a(Team)
        expect(teams[:defendant_team].name).to eq("Defendant Team")
      end
    end

    context "when only defendant team exists" do
      let!(:existing_defendant) { create(:team, name: "Existing Defendant", course: course) }

      before do
        create(:case_team, case: case_record, team: existing_defendant, role: :defendant)
      end

      it "creates plaintiff team and uses existing defendant" do
        teams = service.default_teams

        expect(teams[:plaintiff_team]).to be_a(Team)
        expect(teams[:plaintiff_team].name).to eq("Plaintiff Team")
        expect(teams[:defendant_team]).to eq(existing_defendant)
      end
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

    it "assigns teams to simulation" do
      simulation = service.build_simulation_with_defaults

      expect(simulation.plaintiff_team).to be_present
      expect(simulation.defendant_team).to be_present
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
