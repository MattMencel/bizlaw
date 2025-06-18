# frozen_string_literal: true

class ArbitrationOutcome < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :simulation

  # Delegated associations
  delegate :case, :plaintiff_team, :defendant_team, to: :simulation

  # Validations
  validates :award_amount, presence: true,
                          numericality: { greater_than_or_equal_to: 0 }
  validates :rationale, presence: true,
                       length: { minimum: 100, maximum: 2000 }
  validates :calculated_at, presence: true
  validates :factors_considered, presence: true

  # Enums
  enum :outcome_type, {
    plaintiff_victory: "plaintiff_victory",
    defendant_victory: "defendant_victory",
    split_decision: "split_decision",
    no_award: "no_award"
  }, prefix: :outcome

  # Scopes
  scope :recent_outcomes, -> { order(calculated_at: :desc) }
  scope :by_award_amount, -> { order(:award_amount) }
  scope :plaintiff_wins, -> { where(outcome_type: [ :plaintiff_victory, :split_decision ]) }
  scope :defendant_wins, -> { where(outcome_type: [ :defendant_victory, :no_award ]) }

  # Instance methods
  def plaintiff_won?
    outcome_plaintiff_victory? || (outcome_split_decision? && award_amount > simulation.defendant_max_acceptable)
  end

  def defendant_won?
    outcome_defendant_victory? || outcome_no_award? ||
    (outcome_split_decision? && award_amount <= simulation.defendant_ideal)
  end

  def outcome_summary
    case outcome_type
    when "plaintiff_victory"
      "Strong victory for plaintiff"
    when "defendant_victory"
      "Favorable outcome for defendant"
    when "split_decision"
      "Mixed outcome with partial award"
    when "no_award"
      "No damages awarded"
    end
  end

  def comparison_to_settlement_range
    plaintiff_range = "#{currency(simulation.plaintiff_min_acceptable)} - #{currency(simulation.plaintiff_ideal)}"
    defendant_range = "#{currency(simulation.defendant_ideal)} - #{currency(simulation.defendant_max_acceptable)}"

    {
      award: currency(award_amount),
      plaintiff_expected: plaintiff_range,
      defendant_expected: defendant_range,
      better_for_plaintiff: award_amount >= simulation.plaintiff_min_acceptable,
      better_for_defendant: award_amount <= simulation.defendant_max_acceptable
    }
  end

  def detailed_analysis
    {
      outcome_type: outcome_type,
      award_amount: award_amount,
      outcome_summary: outcome_summary,
      factors_breakdown: factors_considered,
      comparison: comparison_to_settlement_range,
      lessons_learned: generate_lessons_learned
    }
  end

  # Class method to calculate arbitration outcome
  def self.calculate_outcome!(simulation)
    return nil unless simulation.status_arbitration?

    calculator = ArbitrationCalculator.new(simulation)

    outcome = find_or_initialize_by(simulation: simulation)
    outcome.assign_attributes(
      award_amount: calculator.award_amount,
      rationale: calculator.rationale,
      factors_considered: calculator.factors_considered,
      outcome_type: calculator.outcome_type,
      evidence_strength_factor: calculator.evidence_strength_factor,
      argument_quality_factor: calculator.argument_quality_factor,
      negotiation_history_factor: calculator.negotiation_history_factor,
      random_variance: calculator.random_variance,
      calculated_at: Time.current
    )

    outcome.save!
    outcome
  end

  private

  def currency(amount)
    "$#{number_with_delimiter(amount.to_i)}"
  end

  def number_with_delimiter(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  def generate_lessons_learned
    lessons = []

    # Settlement vs arbitration comparison
    if award_amount < simulation.plaintiff_min_acceptable
      lessons << "Plaintiff might have benefited from accepting a settlement above their minimum"
    elsif award_amount > simulation.defendant_max_acceptable
      lessons << "Defendant might have saved money by settling within their maximum range"
    end

    # Negotiation quality impact
    if argument_quality_factor && argument_quality_factor < 0.7
      lessons << "Stronger legal arguments could have improved the outcome"
    end

    # Evidence strength impact
    if evidence_strength_factor && evidence_strength_factor < 0.6
      lessons << "More thorough evidence preparation was needed"
    end

    # Negotiation behavior impact
    if negotiation_history_factor && negotiation_history_factor < 0.5
      lessons << "More reasonable negotiation positions might have led to better settlement opportunities"
    end

    lessons.presence || [ "This case demonstrates the unpredictability of arbitration outcomes" ]
  end
end

# Separate service class for arbitration calculations
class ArbitrationCalculator
  attr_reader :simulation, :evidence_strength_factor, :argument_quality_factor,
              :negotiation_history_factor, :random_variance

  def initialize(simulation)
    @simulation = simulation
    calculate_factors
  end

  def award_amount
    base_award = calculate_base_award
    adjusted_award = apply_factors(base_award)
    apply_variance(adjusted_award)
  end

  def outcome_type
    if award_amount >= simulation.plaintiff_ideal * 0.8
      "plaintiff_victory"
    elsif award_amount <= simulation.defendant_ideal * 1.2
      "defendant_victory"
    elsif award_amount == 0
      "no_award"
    else
      "split_decision"
    end
  end

  def rationale
    build_rationale
  end

  def factors_considered
    {
      "evidence_strength" => {
        "factor" => evidence_strength_factor,
        "impact" => evidence_impact_description
      },
      "argument_quality" => {
        "factor" => argument_quality_factor,
        "impact" => argument_impact_description
      },
      "negotiation_history" => {
        "factor" => negotiation_history_factor,
        "impact" => negotiation_impact_description
      },
      "case_precedents" => {
        "factor" => 0.75, # Baseline for sexual harassment cases
        "impact" => "Typical award range for sexual harassment cases considered"
      },
      "random_variance" => {
        "factor" => random_variance,
        "impact" => "Natural unpredictability of arbitration process"
      }
    }
  end

  private

  def calculate_factors
    @evidence_strength_factor = calculate_evidence_strength
    @argument_quality_factor = calculate_argument_quality
    @negotiation_history_factor = calculate_negotiation_history
    @random_variance = (rand * 0.4) + 0.8 # 0.8 to 1.2 multiplier
  end

  def calculate_base_award
    # Start with midpoint between plaintiff minimum and defendant maximum
    midpoint = (simulation.plaintiff_min_acceptable + simulation.defendant_max_acceptable) / 2.0

    # Adjust based on case type baseline
    case simulation.case.case_type
    when "sexual_harassment"
      midpoint * 1.1 # Slight bias toward plaintiff in harassment cases
    else
      midpoint
    end
  end

  def apply_factors(base_award)
    # Evidence strength (30% weight)
    evidence_adjustment = base_award * 0.3 * (evidence_strength_factor - 0.5)

    # Argument quality (25% weight)
    argument_adjustment = base_award * 0.25 * (argument_quality_factor - 0.5)

    # Negotiation history (15% weight)
    negotiation_adjustment = base_award * 0.15 * (negotiation_history_factor - 0.5)

    adjusted = base_award + evidence_adjustment + argument_adjustment + negotiation_adjustment
    [ adjusted, 0 ].max # Ensure non-negative
  end

  def apply_variance(adjusted_award)
    final_award = adjusted_award * random_variance

    # Ensure within reasonable bounds
    max_reasonable = simulation.plaintiff_ideal * 1.5
    min_reasonable = 0

    final_award.clamp(min_reasonable, max_reasonable).round
  end

  def calculate_evidence_strength
    # This would analyze uploaded documents and case materials
    # For now, use a baseline with some randomness
    base_strength = 0.6
    variance = (rand * 0.4) - 0.2 # -0.2 to +0.2
    (base_strength + variance).clamp(0.1, 0.9)
  end

  def calculate_argument_quality
    # Analyze settlement offer justifications and legal reasoning
    offers = simulation.settlement_offers
    return 0.5 if offers.empty?

    avg_quality = offers.average(:quality_score) || 50
    (avg_quality / 100.0).clamp(0.1, 0.9)
  end

  def calculate_negotiation_history
    rounds = simulation.negotiation_rounds.completed
    return 0.5 if rounds.empty?

    # Analyze reasonableness of positions taken
    reasonable_movement = 0
    total_rounds = rounds.count

    rounds.each do |round|
      plaintiff_offer = round.plaintiff_offer
      defendant_offer = round.defendant_offer

      next unless plaintiff_offer && defendant_offer

      # Check if offers showed reasonable movement toward settlement
      if round.settlement_gap && round.settlement_gap < simulation.plaintiff_ideal
        reasonable_movement += 1
      end
    end

    return 0.5 if total_rounds.zero?

    reasonableness_ratio = reasonable_movement.to_f / total_rounds
    (0.3 + (reasonableness_ratio * 0.4)).clamp(0.1, 0.9)
  end

  def build_rationale
    rationale_parts = []

    rationale_parts << "This arbitration considered multiple factors in determining the award amount."

    if evidence_strength_factor > 0.7
      rationale_parts << "The evidence presented was particularly strong and well-documented."
    elsif evidence_strength_factor < 0.4
      rationale_parts << "The evidence was somewhat limited, affecting the strength of the case."
    end

    if argument_quality_factor > 0.7
      rationale_parts << "Both parties presented well-reasoned legal arguments with appropriate precedent citations."
    elsif argument_quality_factor < 0.4
      rationale_parts << "The legal arguments could have been more comprehensive and better supported."
    end

    if negotiation_history_factor > 0.7
      rationale_parts << "The parties demonstrated good faith negotiation efforts throughout the process."
    elsif negotiation_history_factor < 0.4
      rationale_parts << "The negotiation history showed some unreasonable positions that hindered settlement."
    end

    rationale_parts << "The final award reflects typical outcomes for similar sexual harassment cases, adjusted for the specific circumstances and evidence presented."

    rationale_parts.join(" ")
  end

  def evidence_impact_description
    if evidence_strength_factor > 0.7
      "Strong evidence significantly supported the case"
    elsif evidence_strength_factor < 0.4
      "Limited evidence weakened the overall case strength"
    else
      "Moderate evidence provided reasonable case support"
    end
  end

  def argument_impact_description
    if argument_quality_factor > 0.7
      "High-quality legal arguments enhanced the case presentation"
    elsif argument_quality_factor < 0.4
      "Weak legal arguments detracted from case strength"
    else
      "Adequate legal arguments provided standard case support"
    end
  end

  def negotiation_impact_description
    if negotiation_history_factor > 0.7
      "Reasonable negotiation behavior demonstrated good faith"
    elsif negotiation_history_factor < 0.4
      "Unreasonable negotiation positions hurt the case"
    else
      "Standard negotiation behavior neither helped nor hurt"
    end
  end
end
