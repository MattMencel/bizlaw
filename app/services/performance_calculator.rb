# frozen_string_literal: true

class PerformanceCalculator
  attr_reader :simulation, :team, :user

  def initialize(simulation, team, user)
    @simulation = simulation
    @team = team
    @user = user
  end

  def settlement_quality_score
    # Base score calculation (0-40 points)
    base_score = calculate_settlement_quality_base

    # Apply bonus for client satisfaction
    client_satisfaction_bonus = calculate_client_satisfaction_bonus

    # Apply penalty for unreasonable offers
    reasonableness_penalty = calculate_reasonableness_penalty

    final_score = base_score + client_satisfaction_bonus - reasonableness_penalty
    final_score.clamp(0, 40)
  end

  def legal_strategy_score
    # Base score calculation (0-30 points)
    argument_quality = calculate_argument_quality
    legal_research_bonus = calculate_legal_research_bonus
    precedent_usage_bonus = calculate_precedent_usage_bonus

    final_score = argument_quality + legal_research_bonus + precedent_usage_bonus
    final_score.clamp(0, 30)
  end

  def collaboration_score
    # Base score calculation (0-20 points)
    participation_score = calculate_participation_score
    communication_quality = calculate_communication_quality
    team_contribution = calculate_team_contribution_score

    final_score = participation_score + communication_quality + team_contribution
    final_score.clamp(0, 20)
  end

  def efficiency_score
    # Base score calculation (0-10 points)
    timeliness_score = calculate_timeliness_score
    decision_speed = calculate_decision_speed_score
    process_optimization = calculate_process_optimization_score

    final_score = timeliness_score + decision_speed + process_optimization
    final_score.clamp(0, 10)
  end

  def speed_bonus
    # Bonus points for early completion (0-10 points)
    early_settlement_bonus = calculate_early_settlement_bonus
    quick_response_bonus = calculate_quick_response_bonus

    (early_settlement_bonus + quick_response_bonus).clamp(0, 10)
  end

  def creative_terms_score
    # Bonus points for innovative solutions (0-10 points)
    creative_solutions_bonus = calculate_creative_solutions_bonus
    innovative_terms_bonus = calculate_innovative_terms_bonus

    (creative_solutions_bonus + innovative_terms_bonus).clamp(0, 10)
  end

  private

  # Settlement Quality Calculations (40 points max)
  def calculate_settlement_quality_base
    offers = user_settlement_offers
    return 15 if offers.empty? # Base score for participation

    # Analyze offer progression and client alignment
    latest_offer = offers.last
    client_satisfaction = calculate_offer_client_satisfaction(latest_offer)

    # Convert satisfaction (0-1) to points (15-35)
    (15 + (client_satisfaction * 20)).round
  end

  def calculate_client_satisfaction_bonus
    # Bonus for high client satisfaction (0-5 points)
    offers = user_settlement_offers
    return 0 if offers.empty?

    avg_satisfaction = offers.average(:client_satisfaction_score) || 0.5
    (avg_satisfaction > 0.8) ? 5 : 0
  end

  def calculate_reasonableness_penalty
    # Penalty for consistently unreasonable offers (0-5 points)
    offers = user_settlement_offers
    return 0 if offers.empty?

    unreasonable_count = offers.count { |offer| offer_unreasonable?(offer) }
    penalty_ratio = unreasonable_count.to_f / offers.count

    (penalty_ratio > 0.5) ? 5 : 0
  end

  # Legal Strategy Calculations (30 points max)
  def calculate_argument_quality
    offers = user_settlement_offers
    return 12 if offers.empty? # Base score

    # Average quality of legal justifications
    avg_quality = offers.average(:quality_score) || 50

    # Convert 0-100 quality to 12-25 points
    (12 + ((avg_quality / 100.0) * 13)).round
  end

  def calculate_legal_research_bonus
    # Bonus for citing legal precedents (0-3 points)
    offers = user_settlement_offers

    research_count = offers.count { |offer|
      offer.justification&.include?("precedent") ||
        offer.justification&.include?("case law") ||
        offer.justification&.include?("statute")
    }

    [research_count, 3].min
  end

  def calculate_precedent_usage_bonus
    # Bonus for proper legal precedent usage (0-2 points)
    offers = user_settlement_offers

    precedent_usage = offers.count { |offer| well_cited_precedent?(offer) }
    [precedent_usage, 2].min
  end

  # Collaboration Calculations (20 points max)
  def calculate_participation_score
    # Base participation score (8-12 points)
    team_actions = count_user_team_actions

    case team_actions
    when 0..2 then 8
    when 3..5 then 10
    else 12
    end
  end

  def calculate_communication_quality
    # Quality of team communications (0-5 points)
    messages = user_team_messages
    return 3 if messages.empty? # Default for minimal participation

    # Analyze message quality (simplified)
    quality_indicators = messages.count { |msg|
      msg.length > 50 && # Substantial messages
        !msg.match?(/^(ok|yes|no|sure)$/i) # Not just short responses
    }

    ratio = quality_indicators.to_f / messages.count
    (ratio * 5).round
  end

  def calculate_team_contribution_score
    # Contribution to team success (0-3 points)
    team_score = PerformanceScore.find_by(simulation: simulation, team: team, score_type: "team")
    return 2 if team_score.nil?

    # Higher team scores indicate better individual contributions
    case team_score.total_score
    when 0..70 then 1
    when 71..85 then 2
    else 3
    end
  end

  # Efficiency Calculations (10 points max)
  def calculate_timeliness_score
    # Points for meeting deadlines (0-5 points)
    offers = user_settlement_offers
    return 3 if offers.empty?

    on_time_count = offers.count { |offer| offer_submitted_on_time?(offer) }
    ratio = on_time_count.to_f / offers.count

    (ratio * 5).round
  end

  def calculate_decision_speed_score
    # Points for quick decision making (0-3 points)
    avg_response_time = calculate_average_response_time

    case avg_response_time
    when 0..2 then 3  # Within 2 hours
    when 3..12 then 2 # Within 12 hours
    when 13..24 then 1 # Within 24 hours
    else 0
    end
  end

  def calculate_process_optimization_score
    # Points for efficient process (0-2 points)
    revision_count = count_offer_revisions

    case revision_count
    when 0..1 then 2 # Minimal revisions needed
    when 2..3 then 1 # Some revisions
    else 0
    end
  end

  # Speed Bonus Calculations (10 points max)
  def calculate_early_settlement_bonus
    # Bonus for reaching settlement early (0-7 points)
    return 0 unless simulation.status_completed?
    return 0 unless simulation.settlement_reached?

    rounds_saved = simulation.max_rounds - simulation.current_round
    [rounds_saved * 1.5, 7].min.round
  end

  def calculate_quick_response_bonus
    # Bonus for consistently quick responses (0-3 points)
    avg_response_time = calculate_average_response_time

    case avg_response_time
    when 0..1 then 3
    when 2..4 then 2
    when 5..8 then 1
    else 0
    end
  end

  # Creative Terms Calculations (10 points max)
  def calculate_creative_solutions_bonus
    # Bonus for non-monetary terms (0-6 points)
    offers = user_settlement_offers

    creative_count = offers.count { |offer| includes_creative_terms?(offer) }
    [creative_count * 2, 6].min
  end

  def calculate_innovative_terms_bonus
    # Bonus for unique innovative solutions (0-4 points)
    offers = user_settlement_offers

    innovation_score = offers.sum { |offer| rate_innovation_level(offer) }
    [innovation_score, 4].min
  end

  # Helper Methods
  def user_settlement_offers
    @user_settlement_offers ||= SettlementOffer.where(
      simulation: simulation,
      team: team,
      user: user
    ).order(:created_at)
  end

  def calculate_offer_client_satisfaction(offer)
    # Use ClientRangeValidationService to get satisfaction
    validator = ClientRangeValidationService.new(simulation, team)
    result = validator.validate_offer(offer.amount)
    result[:client_satisfaction] || 0.5
  end

  def offer_unreasonable?(offer)
    # An offer is unreasonable if it's way outside acceptable range
    validator = ClientRangeValidationService.new(simulation, team)
    result = validator.validate_offer(offer.amount)
    result[:feedback_type] == "completely_unreasonable"
  end

  def well_cited_precedent?(offer)
    # Check if offer includes proper legal citations
    justification = offer.justification.to_s.downcase

    # Look for legal citation patterns
    justification.match?(/\b\d+\s+[a-z\.]+\s+\d+\b/) || # Citation format like "123 F.3d 456"
      justification.match?(/\bv\.\s+[a-z]/i) || # Case name format
      justification.include?("precedent") && justification.length > 100
  end

  def count_user_team_actions
    # Count various team actions by the user
    offer_count = user_settlement_offers.count
    message_count = user_team_messages.count
    document_count = user_document_uploads.count

    offer_count + (message_count / 2) + document_count
  end

  def user_team_messages
    # This would connect to a team messaging system
    # For now, return empty array as messaging isn't implemented
    []
  end

  def user_document_uploads
    # Count documents uploaded by the user
    Document.where(
      documentable: simulation.case,
      uploaded_by: user
    )
  end

  def offer_submitted_on_time?(offer)
    # Check if offer was submitted before deadline
    round = simulation.negotiation_rounds.find_by(round_number: offer.round_number)
    return true if round.nil? || round.deadline.nil?

    offer.created_at <= round.deadline
  end

  def calculate_average_response_time
    # Calculate average time between rounds and user's offers
    offers = user_settlement_offers
    return 12 if offers.empty? # Default average

    response_times = offers.map do |offer|
      round = simulation.negotiation_rounds.find_by(round_number: offer.round_number)
      next 12 if round.nil?

      hours_to_respond = ((offer.created_at - round.start_time) / 1.hour)
      [hours_to_respond, 48].min # Cap at 48 hours
    end.compact

    response_times.empty? ? 12 : response_times.average
  end

  def count_offer_revisions
    # Count how many times user revised their offers
    offers = user_settlement_offers
    return 0 if offers.count <= 1

    # Count significant changes (>10% difference) between consecutive offers
    revisions = 0
    offers.each_cons(2) do |prev_offer, curr_offer|
      change_percent = ((curr_offer.amount - prev_offer.amount).abs / prev_offer.amount.to_f) * 100
      revisions += 1 if change_percent > 10
    end

    revisions
  end

  def includes_creative_terms?(offer)
    # Check if offer includes non-monetary creative terms
    terms = offer.additional_terms.to_s.downcase

    creative_indicators = [
      "training", "policy", "mediation", "confidentiality",
      "non-disclosure", "recommendation", "reference",
      "restructuring", "mentorship", "counseling"
    ]

    creative_indicators.any? { |indicator| terms.include?(indicator) }
  end

  def rate_innovation_level(offer)
    # Rate how innovative the offer terms are (0-2 points per offer)
    terms = offer.additional_terms.to_s

    innovation_score = 0
    innovation_score += 1 if terms.length > 100 # Detailed terms
    innovation_score += 1 if terms.match?(/\b(innovative|creative|unique|novel)\b/i)

    innovation_score
  end
end
