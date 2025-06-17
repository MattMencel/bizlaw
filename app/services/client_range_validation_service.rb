# frozen_string_literal: true

class ClientRangeValidationService
  attr_reader :simulation

  # Result classes for structured responses
  ValidationResult = Struct.new(
    :positioning, 
    :satisfaction_score, 
    :mood, 
    :feedback_theme, 
    :pressure_level, 
    :within_acceptable_range, 
    keyword_init: true
  )

  GapAnalysis = Struct.new(
    :gap_size, 
    :gap_category, 
    :settlement_likelihood, 
    :strategic_guidance, 
    keyword_init: true
  )

  def initialize(simulation)
    @simulation = simulation
  end

  def validate_offer(team, offer_amount)
    validate_inputs!(team, offer_amount)
    
    team_role = determine_team_role(team)
    
    case team_role
    when "plaintiff"
      validate_plaintiff_offer(offer_amount)
    when "defendant"
      validate_defendant_offer(offer_amount)
    else
      raise ArgumentError, "Unknown team role: #{team_role}"
    end
  end

  def analyze_settlement_gap(plaintiff_offer, defendant_offer)
    gap_size = plaintiff_offer - defendant_offer
    
    GapAnalysis.new(
      gap_size: gap_size,
      gap_category: categorize_gap(gap_size),
      settlement_likelihood: assess_settlement_likelihood(gap_size),
      strategic_guidance: generate_gap_guidance(gap_size)
    )
  end

  def calculate_pressure_level(team, offer_amount)
    team_role = determine_team_role(team)
    
    case team_role
    when "plaintiff"
      calculate_plaintiff_pressure(offer_amount)
    when "defendant"
      calculate_defendant_pressure(offer_amount)
    end
  end

  def ranges_overlap?
    simulation.plaintiff_min_acceptable <= simulation.defendant_max_acceptable
  end

  def within_settlement_zone?(plaintiff_offer, defendant_offer)
    return false unless ranges_overlap?
    
    plaintiff_offer >= simulation.plaintiff_min_acceptable &&
    plaintiff_offer <= simulation.defendant_max_acceptable &&
    defendant_offer >= simulation.plaintiff_min_acceptable &&
    defendant_offer <= simulation.defendant_max_acceptable
  end

  def adjust_ranges_for_event!(event_type, intensity = :moderate)
    case event_type
    when :media_attention
      adjust_for_media_attention(intensity)
    when :additional_evidence
      adjust_for_additional_evidence(intensity)
    when :ipo_delay
      adjust_for_ipo_delay(intensity)
    when :court_deadline
      adjust_for_court_deadline(intensity)
    when :witness_change
      adjust_for_witness_change(intensity)
    when :expert_testimony
      adjust_for_expert_testimony(intensity)
    else
      raise ArgumentError, "Unknown event type: #{event_type}"
    end
    
    simulation.save!
  end

  private

  def validate_inputs!(team, offer_amount)
    raise ArgumentError, "Offer amount cannot be nil" if offer_amount.nil?
    raise ArgumentError, "Offer amount must be positive" if offer_amount <= 0
    
    unless team_assigned_to_simulation?(team)
      raise ArgumentError, "Team is not assigned to this simulation"
    end
  end

  def team_assigned_to_simulation?(team)
    simulation.case.assigned_teams.include?(team)
  end

  def determine_team_role(team)
    case_team = simulation.case.case_teams.find_by(team: team)
    case_team&.role
  end

  def validate_plaintiff_offer(amount)
    min_acceptable = simulation.plaintiff_min_acceptable
    ideal = simulation.plaintiff_ideal
    
    positioning, satisfaction, mood, theme, pressure = if amount < min_acceptable * 0.9
      [:below_minimum, rand(10..25), "very_unhappy", :unacceptable_amount, :extreme]
    elsif amount < min_acceptable
      [:near_minimum, rand(35..50), "unhappy", :concerning_low, :high]
    elsif amount < (min_acceptable + ideal) / 2
      [:conservative_approach, rand(55..70), "neutral", :strategic_positioning, :moderate]
    elsif amount <= ideal * 1.05
      [:reasonable_opening, rand(70..85), "satisfied", :excellent_positioning, :low]
    elsif amount <= ideal * 1.15
      [:strong_position, rand(80..90), "satisfied", :excellent_positioning, :low]
    else
      [:too_aggressive, rand(20..40), "unhappy", :unrealistic_demand, :moderate]
    end

    ValidationResult.new(
      positioning: positioning,
      satisfaction_score: satisfaction,
      mood: mood,
      feedback_theme: theme,
      pressure_level: pressure,
      within_acceptable_range: amount >= min_acceptable
    )
  end

  def validate_defendant_offer(amount)
    ideal = simulation.defendant_ideal
    max_acceptable = simulation.defendant_max_acceptable
    
    positioning, satisfaction, mood, theme, pressure = if amount <= ideal * 0.9
      [:excellent_position, rand(85..95), "very_satisfied", :conservative_approach, :low]
    elsif amount <= ideal * 1.1
      [:ideal_amount, rand(80..90), "satisfied", :target_achieved, :low]
    elsif amount <= (ideal + max_acceptable) / 2
      [:acceptable_compromise, rand(60..75), "neutral", :reasonable_settlement, :moderate]
    elsif amount <= max_acceptable * 0.95
      [:concerning_amount, rand(35..50), "unhappy", :financial_concern, :high]
    elsif amount <= max_acceptable
      [:approaching_maximum, rand(25..40), "unhappy", :serious_concern, :high]
    else
      [:exceeds_maximum, rand(10..25), "very_unhappy", :unacceptable_exposure, :extreme]
    end

    ValidationResult.new(
      positioning: positioning,
      satisfaction_score: satisfaction,
      mood: mood,
      feedback_theme: theme,
      pressure_level: pressure,
      within_acceptable_range: amount <= max_acceptable
    )
  end

  def calculate_plaintiff_pressure(amount)
    min_acceptable = simulation.plaintiff_min_acceptable
    ideal = simulation.plaintiff_ideal
    
    if amount >= ideal * 0.95
      :low
    elsif amount >= (min_acceptable + ideal) / 2
      :moderate
    elsif amount >= min_acceptable * 1.05
      :high
    else
      :extreme
    end
  end

  def calculate_defendant_pressure(amount)
    ideal = simulation.defendant_ideal
    max_acceptable = simulation.defendant_max_acceptable
    
    if amount <= ideal * 1.1
      :low
    elsif amount <= (ideal + max_acceptable) / 2
      :moderate
    elsif amount <= max_acceptable * 0.95
      :high
    else
      :extreme
    end
  end

  def categorize_gap(gap_size)
    if gap_size <= 0
      :settlement_zone
    elsif gap_size <= simulation.plaintiff_min_acceptable * 0.3
      :negotiable_gap
    elsif gap_size <= simulation.plaintiff_ideal * 0.5
      :moderate_gap
    else
      :large_gap
    end
  end

  def assess_settlement_likelihood(gap_size)
    case categorize_gap(gap_size)
    when :settlement_zone
      :likely
    when :negotiable_gap
      :possible
    when :moderate_gap
      :challenging
    when :large_gap
      :unlikely
    end
  end

  def generate_gap_guidance(gap_size)
    case categorize_gap(gap_size)
    when :settlement_zone
      "Settlement appears within reach with minor adjustments"
    when :negotiable_gap
      "Consider creative terms to bridge remaining gap"
    when :moderate_gap
      "Significant movement needed from both parties"
    when :large_gap
      "Substantial repositioning required for settlement potential"
    end
  end

  # Event adjustment methods
  def adjust_for_media_attention(intensity)
    multiplier = case intensity
    when :low then 0.10
    when :moderate then 0.15
    when :high then 0.20
    end
    
    min_increase = (simulation.plaintiff_min_acceptable * multiplier).round
    ideal_increase = (simulation.plaintiff_ideal * multiplier).round
    
    simulation.plaintiff_min_acceptable += min_increase
    simulation.plaintiff_ideal += ideal_increase
  end

  def adjust_for_additional_evidence(intensity)
    multiplier = case intensity
    when :low then 0.15
    when :moderate then 0.25
    when :high then 0.35
    end
    
    min_increase = (simulation.plaintiff_min_acceptable * multiplier).round
    ideal_increase = (simulation.plaintiff_ideal * multiplier).round
    
    simulation.plaintiff_min_acceptable += min_increase
    simulation.plaintiff_ideal += ideal_increase
  end

  def adjust_for_ipo_delay(intensity)
    multiplier = case intensity
    when :low then 0.30
    when :moderate then 0.40
    when :high then 0.50
    end
    
    max_increase = (simulation.defendant_max_acceptable * multiplier).round
    ideal_increase = (simulation.defendant_ideal * multiplier).round
    
    simulation.defendant_max_acceptable += max_increase
    simulation.defendant_ideal += ideal_increase
  end

  def adjust_for_court_deadline(intensity)
    # Court deadline increases urgency for both sides
    multiplier = case intensity
    when :low then 0.05
    when :moderate then 0.10
    when :high then 0.15
    end
    
    # Plaintiff becomes slightly more flexible
    plaintiff_decrease = (simulation.plaintiff_min_acceptable * multiplier).round
    simulation.plaintiff_min_acceptable -= plaintiff_decrease
    
    # Defendant becomes more willing to pay
    defendant_increase = (simulation.defendant_max_acceptable * multiplier).round
    simulation.defendant_max_acceptable += defendant_increase
  end

  def adjust_for_witness_change(intensity)
    # Similar to additional evidence but smaller impact
    multiplier = case intensity
    when :low then 0.08
    when :moderate then 0.15
    when :high then 0.25
    end
    
    min_increase = (simulation.plaintiff_min_acceptable * multiplier).round
    ideal_increase = (simulation.plaintiff_ideal * multiplier).round
    
    simulation.plaintiff_min_acceptable += min_increase
    simulation.plaintiff_ideal += ideal_increase
  end

  def adjust_for_expert_testimony(intensity)
    # Expert testimony can favor either side, adjust accordingly
    multiplier = case intensity
    when :low then 0.10
    when :moderate then 0.20
    when :high then 0.30
    end
    
    # For now, assume it favors plaintiff (this could be made dynamic)
    min_increase = (simulation.plaintiff_min_acceptable * multiplier).round
    ideal_increase = (simulation.plaintiff_ideal * multiplier).round
    
    simulation.plaintiff_min_acceptable += min_increase
    simulation.plaintiff_ideal += ideal_increase
  end
end