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

    # Get base validation result
    base_result = case team_role
    when "plaintiff"
      validate_plaintiff_offer(offer_amount)
    when "defendant"
      validate_defendant_offer(offer_amount)
    else
      raise ArgumentError, "Unknown team role: #{team_role}"
    end

    # Try to enhance with AI insights
    ai_enhanced_result = enhance_validation_with_ai(team, offer_amount, base_result)
    ai_enhanced_result || base_result
  end

  def analyze_settlement_gap(plaintiff_offer, defendant_offer)
    gap_size = plaintiff_offer - defendant_offer

    # Get base gap analysis
    base_analysis = GapAnalysis.new(
      gap_size: gap_size,
      gap_category: categorize_gap(gap_size),
      settlement_likelihood: assess_settlement_likelihood(gap_size),
      strategic_guidance: generate_gap_guidance(gap_size)
    )

    # Try to enhance with AI insights
    ai_enhanced_analysis = enhance_gap_analysis_with_ai(plaintiff_offer, defendant_offer, base_analysis)
    ai_enhanced_analysis || base_analysis
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

    plaintiff_offer.between?(simulation.plaintiff_min_acceptable, simulation.defendant_max_acceptable) &&
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

  # AI Enhancement Methods

  def enhance_validation_with_ai(team, offer_amount, base_result)
    return nil unless ai_service_available?

    begin
      # Create a mock settlement offer for AI context
      mock_offer = build_validation_context_offer(team, offer_amount)

      ai_service = GoogleAiService.new
      ai_response = ai_service.generate_settlement_feedback(mock_offer)

      # Create enhanced validation result
      ValidationResult.new(
        positioning: base_result.positioning,
        satisfaction_score: ai_response[:satisfaction_score] || base_result.satisfaction_score,
        mood: ai_response[:mood_level] || base_result.mood,
        feedback_theme: infer_feedback_theme_from_ai(ai_response, base_result),
        pressure_level: calculate_ai_enhanced_pressure(ai_response, base_result),
        within_acceptable_range: base_result.within_acceptable_range
      )
    rescue => e
      Rails.logger.warn "AI validation enhancement failed: #{e.message}"
      nil
    end
  end

  def enhance_gap_analysis_with_ai(plaintiff_offer, defendant_offer, base_analysis)
    return nil unless ai_service_available?

    begin
      # Create mock offers for AI context
      mock_plaintiff_offer = build_gap_context_offer("plaintiff", plaintiff_offer)
      mock_defendant_offer = build_gap_context_offer("defendant", defendant_offer)

      ai_service = GoogleAiService.new
      ai_analysis = ai_service.analyze_settlement_options(mock_plaintiff_offer, mock_defendant_offer)

      if ai_analysis && ai_analysis[:creative_options]
        # Enhance base analysis with AI insights
        enhanced_guidance = combine_gap_guidance(base_analysis.strategic_guidance, ai_analysis)

        GapAnalysis.new(
          gap_size: base_analysis.gap_size,
          gap_category: base_analysis.gap_category,
          settlement_likelihood: refine_settlement_likelihood(base_analysis, ai_analysis),
          strategic_guidance: enhanced_guidance
        )
      end
    rescue => e
      Rails.logger.warn "AI gap analysis enhancement failed: #{e.message}"
      nil
    end
  end

  def ai_service_available?
    GoogleAI.enabled?
  rescue
    false
  end

  def build_validation_context_offer(team, amount)
    # Create a mock negotiation round for context
    recent_round = simulation.negotiation_rounds.order(:round_number).last
    recent_round ||= simulation.negotiation_rounds.build(round_number: 1)

    OpenStruct.new(
      team: team,
      negotiation_round: recent_round,
      amount: amount,
      justification: "Validation context for #{determine_team_role(team)} offer"
    )
  end

  def build_gap_context_offer(role, amount)
    # Create mock team for gap analysis
    mock_team = OpenStruct.new(
      case_teams: [OpenStruct.new(role: role)]
    )

    # Create mock negotiation round
    recent_round = simulation.negotiation_rounds.order(:round_number).last
    recent_round ||= simulation.negotiation_rounds.build(round_number: 1)

    OpenStruct.new(
      team: mock_team,
      negotiation_round: recent_round,
      amount: amount,
      justification: "Gap analysis context for #{role}"
    )
  end

  def infer_feedback_theme_from_ai(ai_response, base_result)
    # Use AI sentiment to potentially refine feedback theme
    if ai_response[:satisfaction_score]
      ai_satisfaction = ai_response[:satisfaction_score]

      # Adjust theme based on AI satisfaction score
      if ai_satisfaction >= 85 && base_result.feedback_theme != :excellent_positioning
        case base_result.feedback_theme
        when :strategic_positioning
          :excellent_positioning
        when :reasonable_settlement
          :target_achieved
        else
          base_result.feedback_theme
        end
      elsif ai_satisfaction <= 30 && base_result.feedback_theme != :unacceptable_amount
        case base_result.feedback_theme
        when :strategic_positioning
          :concerning_low
        when :reasonable_settlement
          :financial_concern
        else
          base_result.feedback_theme
        end
      else
        base_result.feedback_theme
      end
    else
      base_result.feedback_theme
    end
  end

  def calculate_ai_enhanced_pressure(ai_response, base_result)
    # Use AI mood to potentially adjust pressure level
    ai_mood = ai_response[:mood_level]

    case ai_mood
    when "very_unhappy"
      :extreme
    when "unhappy"
      (base_result.pressure_level == :low) ? :moderate : :high
    when "very_satisfied"
      :low
    when "satisfied"
      (base_result.pressure_level == :extreme) ? :high : base_result.pressure_level
    else
      base_result.pressure_level
    end
  end

  def combine_gap_guidance(base_guidance, ai_analysis)
    if ai_analysis[:creative_options]&.any?
      # Extract top creative options from AI
      top_options = ai_analysis[:creative_options].first(2)
      creative_text = top_options.join("; ")

      "#{base_guidance} Consider: #{creative_text}."
    else
      base_guidance
    end
  end

  def refine_settlement_likelihood(base_analysis, ai_analysis)
    # Use AI risk assessment to potentially adjust likelihood
    if ai_analysis[:risk_assessment]
      risk_text = ai_analysis[:risk_assessment].downcase

      if risk_text.include?("achievable") || risk_text.include?("possible")
        # AI suggests more optimism
        case base_analysis.settlement_likelihood
        when :unlikely
          :challenging
        when :challenging
          :possible
        else
          base_analysis.settlement_likelihood
        end
      elsif risk_text.include?("difficult") || risk_text.include?("challenging")
        # AI suggests more caution
        case base_analysis.settlement_likelihood
        when :likely
          :possible
        when :possible
          :challenging
        else
          base_analysis.settlement_likelihood
        end
      else
        base_analysis.settlement_likelihood
      end
    else
      base_analysis.settlement_likelihood
    end
  end
end
