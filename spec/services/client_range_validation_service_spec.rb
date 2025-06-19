# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClientRangeValidationService do
  let(:simulation) do
    # Use dynamic values to avoid exposing actual game ranges
    min_acceptable = rand(100_000..200_000)
    ideal = min_acceptable * 2
    defendant_ideal = min_acceptable * 0.5
    defendant_max = min_acceptable + rand(50_000..150_000)

    case_instance = create(:case, :with_teams)
    create(:simulation,
      case: case_instance,
      plaintiff_min_acceptable: min_acceptable,
      plaintiff_ideal: ideal,
      defendant_ideal: defendant_ideal,
      defendant_max_acceptable: defendant_max)
  end

  let(:plaintiff_team) { simulation.case.plaintiff_team }
  let(:defendant_team) { simulation.case.defendant_team }

  describe "#initialize" do
    it "creates service with simulation" do
      service = described_class.new(simulation)
      expect(service.simulation).to eq(simulation)
    end
  end

  describe "#validate_offer" do
    let(:service) { described_class.new(simulation) }

    context "for plaintiff offers" do
      let(:team) { plaintiff_team }

      context "when offer is well above ideal" do
        let(:offer_amount) { simulation.plaintiff_ideal * 1.3 }

        it "returns aggressive positioning result" do
          result = service.validate_offer(team, offer_amount)

          expect(result.positioning).to eq(:too_aggressive)
          expect(result.satisfaction_score).to be_between(20, 40)
          expect(result.mood).to eq("unhappy")
          expect(result.feedback_theme).to eq(:unrealistic_demand)
        end
      end

      context "when offer is near ideal" do
        let(:offer_amount) { simulation.plaintiff_ideal * 1.08 }

        it "returns strong positioning result" do
          result = service.validate_offer(team, offer_amount)

          expect(result.positioning).to eq(:strong_position)
          expect(result.satisfaction_score).to be_between(80, 90)
          expect(result.mood).to eq("satisfied")
          expect(result.feedback_theme).to eq(:excellent_positioning)
        end
      end

      context "when offer is between minimum and ideal" do
        let(:offer_amount) { (simulation.plaintiff_min_acceptable + simulation.plaintiff_ideal) / 2 }

        it "returns reasonable positioning result" do
          result = service.validate_offer(team, offer_amount)

          expect(result.positioning).to eq(:reasonable_opening)
          expect(result.satisfaction_score).to be_between(70, 85)
          expect(result.mood).to eq("satisfied")
          expect(result.feedback_theme).to eq(:excellent_positioning)
        end
      end

      context "when offer is below minimum acceptable" do
        let(:offer_amount) { simulation.plaintiff_min_acceptable * 0.8 }

        it "returns below minimum result" do
          result = service.validate_offer(team, offer_amount)

          expect(result.positioning).to eq(:below_minimum)
          expect(result.satisfaction_score).to be_between(10, 25)
          expect(result.mood).to eq("very_unhappy")
          expect(result.feedback_theme).to eq(:unacceptable_amount)
        end
      end
    end

    context "for defendant offers" do
      let(:team) { defendant_team }

      context "when offer is at or below ideal" do
        let(:offer_amount) { simulation.defendant_ideal * 0.8 }

        it "returns excellent positioning result" do
          result = service.validate_offer(team, offer_amount)

          expect(result.positioning).to eq(:excellent_position)
          expect(result.satisfaction_score).to be_between(85, 95)
          expect(result.mood).to eq("very_satisfied")
          expect(result.feedback_theme).to eq(:conservative_approach)
        end
      end

      context "when offer is at ideal amount" do
        let(:offer_amount) { simulation.defendant_ideal }

        it "returns ideal positioning result" do
          result = service.validate_offer(team, offer_amount)

          expect(result.positioning).to eq(:ideal_amount)
          expect(result.satisfaction_score).to be_between(80, 90)
          expect(result.mood).to eq("satisfied")
          expect(result.feedback_theme).to eq(:target_achieved)
        end
      end

      context "when offer is between ideal and maximum" do
        let(:offer_amount) { (simulation.defendant_ideal + simulation.defendant_max_acceptable) / 2 }

        it "returns acceptable compromise result" do
          result = service.validate_offer(team, offer_amount)

          expect(result.positioning).to eq(:acceptable_compromise)
          expect(result.satisfaction_score).to be_between(60, 75)
          expect(result.mood).to eq("neutral")
          expect(result.feedback_theme).to eq(:reasonable_settlement)
        end
      end

      context "when offer approaches maximum acceptable" do
        let(:offer_amount) { simulation.defendant_max_acceptable * 0.9 }

        it "returns concerning amount result" do
          result = service.validate_offer(team, offer_amount)

          expect(result.positioning).to eq(:concerning_amount)
          expect(result.satisfaction_score).to be_between(35, 50)
          expect(result.mood).to eq("unhappy")
          expect(result.feedback_theme).to eq(:financial_concern)
        end
      end

      context "when offer exceeds maximum acceptable" do
        let(:offer_amount) { simulation.defendant_max_acceptable * 1.2 }

        it "returns exceeds maximum result" do
          result = service.validate_offer(team, offer_amount)

          expect(result.positioning).to eq(:exceeds_maximum)
          expect(result.satisfaction_score).to be_between(10, 25)
          expect(result.mood).to eq("very_unhappy")
          expect(result.feedback_theme).to eq(:unacceptable_exposure)
        end
      end
    end
  end

  describe "#analyze_settlement_gap" do
    let(:service) { described_class.new(simulation) }

    context "when teams are far apart" do
      let(:plaintiff_offer) { simulation.plaintiff_ideal * 1.15 }
      let(:defendant_offer) { simulation.defendant_ideal }

      it "identifies large settlement gap" do
        result = service.analyze_settlement_gap(plaintiff_offer, defendant_offer)

        expect(result.gap_size).to eq(plaintiff_offer - defendant_offer)
        expect(result.gap_category).to eq(:large_gap)
        expect(result.settlement_likelihood).to eq(:unlikely)
        expect(result.strategic_guidance).to include("repositioning required")
      end
    end

    context "when teams are in potential settlement zone" do
      let(:plaintiff_offer) { simulation.plaintiff_min_acceptable * 1.1 }
      let(:defendant_offer) { simulation.plaintiff_min_acceptable * 1.05 }

      it "identifies settlement zone overlap" do
        result = service.analyze_settlement_gap(plaintiff_offer, defendant_offer)

        expect(result.gap_size).to eq(plaintiff_offer - defendant_offer)
        expect(result.gap_category).to eq(:negotiable_gap)
        expect(result.settlement_likelihood).to eq(:possible)
        expect(result.strategic_guidance).to include("creative terms")
      end
    end

    context "when offers overlap significantly" do
      let(:plaintiff_offer) { simulation.plaintiff_min_acceptable * 1.02 }
      let(:defendant_offer) { simulation.plaintiff_min_acceptable * 1.05 }

      it "identifies immediate settlement potential" do
        result = service.analyze_settlement_gap(plaintiff_offer, defendant_offer)

        expect(result.gap_size).to eq(plaintiff_offer - defendant_offer) # Negative indicates overlap
        expect(result.gap_category).to eq(:settlement_zone)
        expect(result.settlement_likelihood).to eq(:likely)
        expect(result.strategic_guidance).to include("within reach")
      end
    end
  end

  describe "#calculate_pressure_level" do
    let(:service) { described_class.new(simulation) }

    context "for plaintiff team" do
      let(:team) { plaintiff_team }

      it "calculates low pressure for offers near ideal" do
        pressure = service.calculate_pressure_level(team, simulation.plaintiff_ideal * 0.97)
        expect(pressure).to eq(:low)
      end

      it "calculates moderate pressure for offers between ranges" do
        midpoint = (simulation.plaintiff_min_acceptable + simulation.plaintiff_ideal) / 2
        pressure = service.calculate_pressure_level(team, midpoint)
        expect(pressure).to eq(:moderate)
      end

      it "calculates high pressure for offers near minimum" do
        pressure = service.calculate_pressure_level(team, simulation.plaintiff_min_acceptable * 1.07)
        expect(pressure).to eq(:high)
      end

      it "calculates extreme pressure for offers below minimum" do
        pressure = service.calculate_pressure_level(team, simulation.plaintiff_min_acceptable * 0.93)
        expect(pressure).to eq(:extreme)
      end
    end

    context "for defendant team" do
      let(:team) { defendant_team }

      it "calculates low pressure for offers near ideal" do
        pressure = service.calculate_pressure_level(team, simulation.defendant_ideal * 1.07)
        expect(pressure).to eq(:low)
      end

      it "calculates moderate pressure for mid-range offers" do
        midpoint = (simulation.defendant_ideal + simulation.defendant_max_acceptable) / 2
        pressure = service.calculate_pressure_level(team, midpoint)
        expect(pressure).to eq(:moderate)
      end

      it "calculates high pressure for offers near maximum" do
        pressure = service.calculate_pressure_level(team, simulation.defendant_max_acceptable * 0.92)
        expect(pressure).to eq(:high)
      end

      it "calculates extreme pressure for offers exceeding maximum" do
        pressure = service.calculate_pressure_level(team, simulation.defendant_max_acceptable * 1.12)
        expect(pressure).to eq(:extreme)
      end
    end
  end

  describe "#ranges_overlap?" do
    let(:service) { described_class.new(simulation) }

    it "returns true when plaintiff minimum is less than defendant maximum" do
      # plaintiff_min_acceptable: 150_000, defendant_max_acceptable: 250_000
      expect(service.ranges_overlap?).to be true
    end

    context "when ranges don't overlap" do
      let(:simulation) do
        base_amount = rand(100_000..150_000)
        create(:simulation,
          plaintiff_min_acceptable: base_amount * 3,
          plaintiff_ideal: base_amount * 4,
          defendant_ideal: base_amount * 0.5,
          defendant_max_acceptable: base_amount * 2)
      end

      it "returns false when plaintiff minimum exceeds defendant maximum" do
        expect(service.ranges_overlap?).to be false
      end
    end
  end

  describe "#within_settlement_zone?" do
    let(:service) { described_class.new(simulation) }

    it "returns true when both offers are within overlap zone" do
      plaintiff_offer = simulation.plaintiff_min_acceptable * 1.15
      defendant_offer = simulation.plaintiff_min_acceptable * 1.3
      result = service.within_settlement_zone?(plaintiff_offer, defendant_offer)
      expect(result).to be true
    end

    it "returns false when plaintiff offer is too high" do
      plaintiff_offer = simulation.plaintiff_ideal * 1.15
      defendant_offer = simulation.defendant_max_acceptable * 0.8
      result = service.within_settlement_zone?(plaintiff_offer, defendant_offer)
      expect(result).to be false
    end

    it "returns false when defendant offer is too low" do
      plaintiff_offer = simulation.plaintiff_min_acceptable * 1.15
      defendant_offer = simulation.defendant_ideal * 0.7
      result = service.within_settlement_zone?(plaintiff_offer, defendant_offer)
      expect(result).to be false
    end
  end

  describe "#adjust_ranges_for_event!" do
    let(:service) { described_class.new(simulation) }

    context "for media attention event" do
      it "increases plaintiff ranges" do
        original_min = simulation.plaintiff_min_acceptable
        original_ideal = simulation.plaintiff_ideal

        service.adjust_ranges_for_event!(:media_attention, :moderate)

        simulation.reload
        expect(simulation.plaintiff_min_acceptable).to be > original_min
        expect(simulation.plaintiff_ideal).to be > original_ideal
      end
    end

    context "for additional evidence event" do
      it "adjusts ranges based on evidence strength" do
        original_min = simulation.plaintiff_min_acceptable

        service.adjust_ranges_for_event!(:additional_evidence, :high)

        simulation.reload
        expect(simulation.plaintiff_min_acceptable).to be > original_min
      end
    end

    context "for IPO delay event" do
      it "increases defendant maximum acceptable" do
        original_max = simulation.defendant_max_acceptable
        original_ideal = simulation.defendant_ideal

        service.adjust_ranges_for_event!(:ipo_delay, :high)

        simulation.reload
        expect(simulation.defendant_max_acceptable).to be > original_max
        expect(simulation.defendant_ideal).to be > original_ideal
      end
    end

    context "for court deadline event" do
      it "increases urgency for both sides" do
        original_plaintiff_min = simulation.plaintiff_min_acceptable
        original_defendant_max = simulation.defendant_max_acceptable

        service.adjust_ranges_for_event!(:court_deadline, :high)

        simulation.reload
        expect(simulation.plaintiff_min_acceptable).to be < original_plaintiff_min
        expect(simulation.defendant_max_acceptable).to be > original_defendant_max
      end
    end
  end

  describe "ValidationResult" do
    let(:result) do
      ClientRangeValidationService::ValidationResult.new(
        positioning: :strong_position,
        satisfaction_score: 85,
        mood: "satisfied",
        feedback_theme: :excellent_positioning,
        pressure_level: :low,
        within_acceptable_range: true
      )
    end

    it "has all required attributes" do
      expect(result.positioning).to eq(:strong_position)
      expect(result.satisfaction_score).to eq(85)
      expect(result.mood).to eq("satisfied")
      expect(result.feedback_theme).to eq(:excellent_positioning)
      expect(result.pressure_level).to eq(:low)
      expect(result.within_acceptable_range).to be true
    end
  end

  describe "GapAnalysis" do
    let(:gap_analysis) do
      ClientRangeValidationService::GapAnalysis.new(
        gap_size: 50_000,
        gap_category: :negotiable_gap,
        settlement_likelihood: :possible,
        strategic_guidance: "Consider creative terms to bridge remaining gap"
      )
    end

    it "has all required attributes" do
      expect(gap_analysis.gap_size).to eq(50_000)
      expect(gap_analysis.gap_category).to eq(:negotiable_gap)
      expect(gap_analysis.settlement_likelihood).to eq(:possible)
      expect(gap_analysis.strategic_guidance).to eq("Consider creative terms to bridge remaining gap")
    end
  end

  describe "error handling" do
    let(:service) { described_class.new(simulation) }

    it "raises error for invalid team" do
      # Create a team that's not assigned to this simulation
      other_case = create(:case, :with_teams)
      invalid_team = other_case.plaintiff_team

      expect {
        service.validate_offer(invalid_team, 100_000)
      }.to raise_error(ArgumentError, "Team is not assigned to this simulation")
    end

    it "raises error for negative offer amount" do
      expect {
        service.validate_offer(plaintiff_team, -1000)
      }.to raise_error(ArgumentError, "Offer amount must be positive")
    end

    it "raises error for nil offer amount" do
      expect {
        service.validate_offer(plaintiff_team, nil)
      }.to raise_error(ArgumentError, "Offer amount cannot be nil")
    end
  end
end
