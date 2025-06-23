# frozen_string_literal: true

class ClientFeedbackService
  attr_reader :simulation, :dynamics_service, :range_validation_service

  def initialize(simulation)
    @simulation = simulation
    @dynamics_service = SimulationDynamicsService.new(simulation)
    @range_validation_service = ClientRangeValidationService.new(simulation)
  end

  # Main entry point for generating feedback after settlement offer submission
  def generate_feedback_for_offer!(settlement_offer)
    team = settlement_offer.team
    round_number = settlement_offer.negotiation_round.round_number

    # Generate range-based feedback using the new validation service
    range_feedback = generate_range_based_feedback(settlement_offer)

    # Generate round-specific strategic guidance if needed
    strategic_feedback = generate_strategic_guidance_if_needed(team, round_number)

    # Generate pressure response feedback if events were triggered
    pressure_feedback = generate_pressure_response_if_needed(team, round_number)

    [range_feedback, strategic_feedback, pressure_feedback].compact
  end

  # Generate AI-enhanced feedback when simulation events are triggered
  def generate_event_feedback!(event, affected_teams = nil)
    affected_teams ||= [simulation.plaintiff_team, simulation.defendant_team].compact

    feedbacks = []

    affected_teams.each do |team|
      next unless team

      # Try AI-enhanced event feedback first
      ai_feedback = generate_ai_enhanced_event_feedback(event, team)

      feedback = if ai_feedback && ai_feedback[:source] == "ai"
        ClientFeedback.create!(
          simulation: simulation,
          team: team,
          feedback_type: :pressure_response,
          mood_level: ai_feedback[:mood_level],
          satisfaction_score: ai_feedback[:satisfaction_score],
          feedback_text: ai_feedback[:feedback_text],
          triggered_by_round: simulation.current_round
        )
      else
        # Fallback to existing rule-based feedback
        ClientFeedback.generate_pressure_response(
          simulation,
          team,
          simulation.current_round,
          event.event_type
        )
      end

      feedbacks << feedback if feedback
    end

    feedbacks
  end

  # Generate round transition feedback (between rounds)
  def generate_round_transition_feedback!(from_round, to_round)
    feedbacks = []

    [simulation.plaintiff_team, simulation.defendant_team].compact.each do |team|
      # Skip if team hasn't submitted an offer in the completed round
      completed_round = simulation.negotiation_rounds.find_by(round_number: from_round)
      next unless completed_round

      team_role = team.case_teams.find_by(case: simulation.case)&.role
      next unless team_role

      has_offer = if team_role == "plaintiff"
        completed_round.has_plaintiff_offer?
      else
        completed_round.has_defendant_offer?
      end

      next unless has_offer

      # Generate transition feedback based on round outcomes
      feedback = generate_transition_feedback(team, from_round, to_round, completed_round)
      feedbacks << feedback if feedback
    end

    feedbacks
  end

  # Generate feedback for settlement reached
  def generate_settlement_feedback!(final_round)
    return [] unless final_round.settlement_reached?

    feedbacks = []

    [simulation.plaintiff_team, simulation.defendant_team].compact.each do |team|
      feedback = generate_settlement_satisfaction_feedback(team, final_round)
      feedbacks << feedback if feedback
    end

    feedbacks
  end

  # Generate feedback for arbitration trigger
  def generate_arbitration_feedback!
    feedbacks = []

    [simulation.plaintiff_team, simulation.defendant_team].compact.each do |team|
      feedback = generate_arbitration_warning_feedback(team)
      feedbacks << feedback if feedback
    end

    feedbacks
  end

  # Get comprehensive feedback summary for a team
  def get_feedback_summary_for_team(team, round_number = nil)
    round_number ||= simulation.current_round

    feedbacks = simulation.client_feedbacks
      .where(team: team)
      .where("triggered_by_round <= ?", round_number)
      .recent_feedback
      .limit(10)

    {
      recent_feedbacks: feedbacks.map(&:formatted_message),
      current_mood: calculate_current_mood(team, round_number),
      satisfaction_trend: calculate_satisfaction_trend(team, round_number),
      key_concerns: identify_key_concerns(team, round_number),
      strategic_recommendations: get_strategic_recommendations(team, round_number)
    }
  end

  # Real-time client mood indicator (without revealing specific numbers)
  def get_client_mood_indicator(team)
    latest_feedback = simulation.client_feedbacks
      .where(team: team)
      .recent_feedback
      .first

    return default_mood_indicator unless latest_feedback

    {
      mood_emoji: latest_feedback.mood_emoji,
      mood_description: latest_feedback.mood_description,
      satisfaction_level: satisfaction_level_descriptor(latest_feedback.satisfaction_score),
      last_updated: latest_feedback.created_at,
      trend: calculate_mood_trend(team),
      guidance: latest_feedback.impact_on_future_rounds
    }
  end

  private

  def generate_strategic_guidance_if_needed(team, round_number)
    # Generate strategic guidance every 2 rounds or if satisfaction is low
    return nil unless should_provide_strategic_guidance?(team, round_number)

    ClientFeedback.generate_strategy_guidance(simulation, team, round_number)
  end

  def generate_pressure_response_if_needed(team, round_number)
    # Check if any events were triggered this round
    recent_events = simulation.simulation_events
      .where(trigger_round: round_number)
      .where("triggered_at >= ?", 1.hour.ago)

    return nil if recent_events.empty?

    # Generate pressure response for the most impactful recent event
    most_impactful_event = recent_events.order(:triggered_at).last

    ClientFeedback.generate_pressure_response(
      simulation,
      team,
      round_number,
      most_impactful_event.event_type
    )
  end

  def generate_transition_feedback(team, from_round, to_round, completed_round)
    case_team = team.case_teams.find_by(case: simulation.case)
    role = case_team&.role
    return nil unless role

    # Analyze the completed round for feedback themes
    feedback_themes = analyze_round_performance(team, completed_round)

    # Try AI-enhanced transition feedback
    ai_feedback = generate_ai_enhanced_transition_feedback(team, from_round, to_round, feedback_themes)

    if ai_feedback && ai_feedback[:source] == "ai"
      ClientFeedback.create!(
        simulation: simulation,
        team: team,
        feedback_type: :strategy_guidance,
        mood_level: ai_feedback[:mood_level],
        satisfaction_score: ai_feedback[:satisfaction_score],
        feedback_text: ai_feedback[:feedback_text],
        triggered_by_round: to_round
      )
    else
      # Fallback to rule-based transition feedback
      mood, satisfaction, message = calculate_transition_feedback(
        role, from_round, to_round, feedback_themes
      )

      ClientFeedback.create!(
        simulation: simulation,
        team: team,
        feedback_type: :strategy_guidance,
        mood_level: mood,
        satisfaction_score: satisfaction,
        feedback_text: message,
        triggered_by_round: to_round
      )
    end
  end

  def generate_settlement_satisfaction_feedback(team, final_round)
    case_team = team.case_teams.find_by(case: simulation.case)
    role = case_team&.role
    return nil unless role

    # Analyze final settlement terms
    team_offer = if role == "plaintiff"
      final_round.plaintiff_offer
    else
      final_round.defendant_offer
    end

    opposing_offer = if role == "plaintiff"
      final_round.defendant_offer
    else
      final_round.plaintiff_offer
    end

    return nil unless team_offer && opposing_offer

    settlement_amount = (team_offer.amount + opposing_offer.amount) / 2.0

    # Try AI-enhanced settlement satisfaction feedback
    ai_feedback = generate_ai_enhanced_settlement_feedback(team_offer, settlement_amount, role)

    if ai_feedback && ai_feedback[:source] == "ai"
      ClientFeedback.create!(
        simulation: simulation,
        team: team,
        feedback_type: :settlement_satisfaction,
        mood_level: ai_feedback[:mood_level],
        satisfaction_score: ai_feedback[:satisfaction_score],
        feedback_text: ai_feedback[:feedback_text],
        triggered_by_round: final_round.round_number
      )
    else
      # Fallback to rule-based settlement satisfaction
      mood, satisfaction, message = calculate_settlement_satisfaction(role, settlement_amount)

      ClientFeedback.create!(
        simulation: simulation,
        team: team,
        feedback_type: :settlement_satisfaction,
        mood_level: mood,
        satisfaction_score: satisfaction,
        feedback_text: message,
        triggered_by_round: final_round.round_number
      )
    end
  end

  def generate_arbitration_warning_feedback(team)
    case_team = team.case_teams.find_by(case: simulation.case)
    role = case_team&.role
    return nil unless role

    mood = "unhappy"
    satisfaction = 30
    message = if role == "plaintiff"
      "Client disappointed that settlement negotiations failed. Arbitration outcome is now uncertain and costly."
    else
      "Client concerned about proceeding to arbitration. Settlement would have provided more predictable resolution."
    end

    ClientFeedback.create!(
      simulation: simulation,
      team: team,
      feedback_type: :strategy_guidance,
      mood_level: mood,
      satisfaction_score: satisfaction,
      feedback_text: message,
      triggered_by_round: simulation.current_round
    )
  end

  def should_provide_strategic_guidance?(team, round_number)
    # Provide guidance every 2 rounds
    return true if (round_number % 2).zero?

    # Provide guidance if recent satisfaction is low
    recent_feedback = simulation.client_feedbacks
      .where(team: team)
      .where("triggered_by_round >= ?", round_number - 1)
      .order(:created_at)
      .last

    recent_feedback&.satisfaction_score&.< 50
  end

  def analyze_round_performance(team, round)
    themes = []

    team_role = team.case_teams.find_by(case: simulation.case)&.role
    team_offer = if team_role == "plaintiff"
      round.plaintiff_offer
    else
      round.defendant_offer
    end

    if team_offer
      # Analyze offer quality
      if team_offer.quality_score && team_offer.quality_score > 75
        themes << :high_quality_arguments
      elsif team_offer.quality_score && team_offer.quality_score < 40
        themes << :low_quality_arguments
      end

      # Analyze strategic positioning
      themes << if team_offer.within_client_expectations?
        :good_positioning
      else
        :poor_positioning
      end

      # Analyze movement from previous round
      movement = team_offer.movement_from_previous
      if movement && movement.abs > 10000
        themes << :significant_movement
      elsif movement && movement.abs < 2000
        themes << :minimal_movement
      end
    end

    # Analyze round outcome
    if round.settlement_reached?
      themes << :settlement_reached
    elsif round.settlement_gap && round.settlement_gap < 50000
      themes << :close_to_settlement
    elsif round.settlement_gap && round.settlement_gap > 200000
      themes << :far_from_settlement
    end

    themes
  end

  def calculate_transition_feedback(role, from_round, to_round, themes)
    base_satisfaction = 60
    mood = "neutral"

    message_parts = []

    # Round progression context
    message_parts << if to_round <= 2
      "Early negotiation progress shows"
    elsif to_round <= 4
      "Mid-negotiation analysis indicates"
    else
      "As we approach final rounds, assessment shows"
    end

    # Performance-based feedback
    if themes.include?(:high_quality_arguments)
      message_parts << "strong legal reasoning in your position"
      base_satisfaction += 10
    elsif themes.include?(:low_quality_arguments)
      message_parts << "room for improvement in argument development"
      base_satisfaction -= 10
    end

    if themes.include?(:good_positioning)
      message_parts << "and strategic positioning aligned with our goals"
      base_satisfaction += 5
    elsif themes.include?(:poor_positioning)
      message_parts << "but positioning that may need adjustment"
      base_satisfaction -= 8
    end

    # Settlement progress feedback
    if themes.include?(:settlement_reached)
      message_parts << ". Excellent work reaching agreement!"
      mood = "very_satisfied"
      base_satisfaction = 95
    elsif themes.include?(:close_to_settlement)
      message_parts << ". We're very close to a resolution."
      mood = "satisfied"
      base_satisfaction += 15
    elsif themes.include?(:far_from_settlement)
      message_parts << ". Gap remains significant - consider strategic adjustments."
      mood = "unhappy"
      base_satisfaction -= 15
    end

    # Movement analysis
    if themes.include?(:significant_movement)
      message_parts << " Your willingness to negotiate is noted."
    elsif themes.include?(:minimal_movement)
      message_parts << " More flexibility may be needed to reach resolution."
    end

    # Determine final mood based on satisfaction
    if base_satisfaction >= 80
      mood = "very_satisfied"
    elsif base_satisfaction >= 65
      mood = "satisfied"
    elsif base_satisfaction <= 35
      mood = "very_unhappy"
    elsif base_satisfaction <= 50
      mood = "unhappy"
    end

    final_satisfaction = [base_satisfaction, 100].min
    final_satisfaction = [final_satisfaction, 0].max

    [mood, final_satisfaction, message_parts.join(" ")]
  end

  def calculate_settlement_satisfaction(role, settlement_amount)
    if role == "plaintiff"
      if settlement_amount >= simulation.plaintiff_ideal * 0.9
        ["very_satisfied", 95, "Client extremely pleased with settlement outcome. This exceeds expectations and provides excellent compensation."]
      elsif settlement_amount >= simulation.plaintiff_min_acceptable * 1.2
        ["satisfied", 85, "Client satisfied with settlement. This provides fair compensation for the harm suffered."]
      elsif settlement_amount >= simulation.plaintiff_min_acceptable
        ["neutral", 70, "Client accepts settlement as reasonable resolution, though hoped for more."]
      else
        ["unhappy", 40, "Client disappointed with settlement amount but glad to avoid arbitration uncertainty."]
      end
    elsif settlement_amount <= simulation.defendant_ideal * 1.2
      ["very_satisfied", 95, "Client very pleased with settlement cost. This resolves the matter efficiently and reasonably."]
    elsif settlement_amount <= simulation.defendant_max_acceptable * 0.8
      ["satisfied", 85, "Client satisfied with settlement terms. Cost is acceptable for resolution."]
    elsif settlement_amount <= simulation.defendant_max_acceptable
      ["neutral", 70, "Client accepts settlement cost as necessary to avoid trial uncertainty."]
    else
      ["unhappy", 40, "Client concerned about settlement cost but relieved to avoid potential trial risks."]
    end
  end

  def calculate_current_mood(team, round_number)
    recent_feedbacks = simulation.client_feedbacks
      .where(team: team)
      .where("triggered_by_round <= ?", round_number)
      .order(:created_at)
      .last(3)

    return "neutral" if recent_feedbacks.empty?

    # Weight recent feedback more heavily
    weights = [0.2, 0.3, 0.5] # oldest to newest
    mood_scores = recent_feedbacks.map { |f| mood_to_score(f.mood_level) }

    weighted_score = mood_scores.zip(weights[-mood_scores.length..]).sum { |score, weight| score * weight }
    score_to_mood(weighted_score)
  end

  def calculate_satisfaction_trend(team, round_number)
    recent_scores = simulation.client_feedbacks
      .where(team: team)
      .where("triggered_by_round <= ?", round_number)
      .order(:created_at)
      .last(3)
      .pluck(:satisfaction_score)

    return "stable" if recent_scores.length < 2

    if recent_scores.last > recent_scores.first + 10
      "improving"
    elsif recent_scores.last < recent_scores.first - 10
      "declining"
    else
      "stable"
    end
  end

  def identify_key_concerns(team, round_number)
    concerns = []

    # Analyze recent feedback for concerning patterns
    recent_feedbacks = simulation.client_feedbacks
      .where(team: team)
      .where("triggered_by_round <= ?", round_number)
      .order(:created_at)
      .last(5)

    low_satisfaction_count = recent_feedbacks.count { |f| f.satisfaction_score < 50 }
    if low_satisfaction_count >= 2
      concerns << "Recent strategic decisions causing client concern"
    end

    # Check for stalled negotiations
    current_round_obj = simulation.current_negotiation_round
    if current_round_obj&.settlement_gap && current_round_obj.settlement_gap > 150000
      concerns << "Large gap between positions requiring creative solutions"
    end

    # Check for time pressure
    if round_number >= simulation.total_rounds - 1
      concerns << "Time pressure mounting as negotiation nears end"
    end

    concerns
  end

  def get_strategic_recommendations(team, round_number)
    recommendations = []

    case_team = team.case_teams.find_by(case: simulation.case)
    role = case_team&.role

    # Round-specific recommendations
    recommendations << if round_number <= 2
      "Focus on establishing strong legal foundation for your position"
    elsif round_number <= 4
      "Consider non-monetary terms to bridge gaps creatively"
    else
      "Time to make final strategic decisions for resolution"
    end

    # Role-specific recommendations
    if role == "plaintiff"
      if simulation.plaintiff_min_acceptable > simulation.defendant_max_acceptable
        recommendations << "Current positions may require adjustment for settlement possibility"
      end
    else
      recent_events = simulation.simulation_events.where("trigger_round >= ?", round_number - 1)
      if recent_events.any?
        recommendations << "Recent developments may justify increased settlement investment"
      end
    end

    recommendations
  end

  def calculate_mood_trend(team)
    recent_moods = simulation.client_feedbacks
      .where(team: team)
      .order(:created_at)
      .last(3)
      .map { |f| mood_to_score(f.mood_level) }

    return "stable" if recent_moods.length < 2

    trend = recent_moods.last - recent_moods.first
    if trend > 0.5
      "improving"
    elsif trend < -0.5
      "declining"
    else
      "stable"
    end
  end

  def satisfaction_level_descriptor(score)
    case score
    when 90..100 then "Very High"
    when 75..89 then "High"
    when 60..74 then "Moderate"
    when 40..59 then "Low"
    when 0..39 then "Very Low"
    else "Unknown"
    end
  end

  def default_mood_indicator
    {
      mood_emoji: "😐",
      mood_description: "Neutral",
      satisfaction_level: "Moderate",
      last_updated: Time.current,
      trend: "stable",
      guidance: "Client ready to begin negotiations"
    }
  end

  def mood_to_score(mood_level)
    case mood_level
    when "very_satisfied" then 1.0
    when "satisfied" then 0.75
    when "neutral" then 0.5
    when "unhappy" then 0.25
    when "very_unhappy" then 0.0
    else 0.5
    end
  end

  def score_to_mood(score)
    case score
    when 0.9..1.0 then "very_satisfied"
    when 0.7..0.89 then "satisfied"
    when 0.3..0.69 then "neutral"
    when 0.1..0.29 then "unhappy"
    when 0.0..0.09 then "very_unhappy"
    else "neutral"
    end
  end

  # AI-enhanced range-based feedback generation method
  def generate_range_based_feedback(settlement_offer)
    team = settlement_offer.team
    amount = settlement_offer.amount

    # Use the range validation service to assess the offer
    validation_result = range_validation_service.validate_offer(team, amount)

    # Try to generate AI-enhanced feedback
    ai_feedback = generate_ai_enhanced_feedback(settlement_offer, validation_result)

    if ai_feedback && ai_feedback[:source] == "ai"
      # Use AI-enhanced feedback
      ClientFeedback.create!(
        simulation: simulation,
        team: team,
        feedback_type: :offer_reaction,
        mood_level: ai_feedback[:mood_level] || validation_result.mood,
        satisfaction_score: ai_feedback[:satisfaction_score] || validation_result.satisfaction_score,
        feedback_text: ai_feedback[:feedback_text],
        triggered_by_round: settlement_offer.negotiation_round.round_number,
        settlement_offer: settlement_offer
      )
    else
      # Fallback to rule-based feedback
      feedback_text = generate_feedback_message(team, validation_result, amount)

      ClientFeedback.create!(
        simulation: simulation,
        team: team,
        feedback_type: :offer_reaction,
        mood_level: validation_result.mood,
        satisfaction_score: validation_result.satisfaction_score,
        feedback_text: feedback_text,
        triggered_by_round: settlement_offer.negotiation_round.round_number,
        settlement_offer: settlement_offer
      )
    end
  end

  private

  def generate_feedback_message(team, validation_result, amount)
    team_role = determine_team_role(team)

    case team_role
    when "plaintiff"
      generate_plaintiff_feedback_message(validation_result)
    when "defendant"
      generate_defendant_feedback_message(validation_result)
    else
      "Client reviewing the settlement offer."
    end
  end

  def generate_plaintiff_feedback_message(result)
    case result.feedback_theme
    when :unrealistic_demand
      "Client concerned that this demand may be too aggressive and could alienate the defendant. Consider a more strategic opening position."
    when :excellent_positioning
      "Client is pleased with this strong position. This demonstrates confidence while remaining within reasonable negotiation bounds."
    when :strategic_positioning
      "Client finds this positioning reasonable and strategic. Shows good balance between ambition and pragmatism."
    when :conservative_approach
      "Client accepts this conservative approach but hopes for more assertive positioning in future rounds."
    when :unacceptable_amount
      "Client is very disappointed with this amount. This falls well below expectations and may not be worth pursuing."
    when :concerning_low
      "Client is concerned this amount is too low. We should aim higher to properly reflect the value of our case."
    else
      "Client is reviewing the settlement position and will provide guidance on next steps."
    end
  end

  def generate_defendant_feedback_message(result)
    case result.feedback_theme
    when :conservative_approach
      "Client pleased with this conservative approach. This keeps exposure minimal while showing good faith."
    when :target_achieved
      "Client satisfied with reaching the target settlement range. This represents ideal resolution for the company."
    when :reasonable_settlement
      "Client views this as an acceptable compromise. While higher than preferred, it's within acceptable bounds."
    when :financial_concern
      "Client getting concerned about the financial impact. This amount is approaching uncomfortable territory."
    when :unacceptable_exposure
      "Client very worried about this exposure level. This exceeds acceptable limits and creates significant risk."
    when :serious_concern
      "Client expressing serious concerns about settlement cost. Approaching maximum acceptable levels."
    else
      "Client is evaluating the settlement offer and considering response options."
    end
  end

  def determine_team_role(team)
    case_team = simulation.case.case_teams.find_by(team: team)
    case_team&.role
  end

  # AI Enhancement Methods

  def generate_ai_enhanced_feedback(settlement_offer, validation_result)
    return nil unless ai_service_available?

    begin
      ai_service = GoogleAiService.new
      ai_response = ai_service.generate_settlement_feedback(settlement_offer)

      # Merge AI insights with validation result
      {
        feedback_text: ai_response[:feedback_text],
        mood_level: ai_response[:mood_level] || validation_result.mood,
        satisfaction_score: ai_response[:satisfaction_score] || validation_result.satisfaction_score,
        strategic_guidance: ai_response[:strategic_guidance],
        source: ai_response[:source] || "ai"
      }
    rescue => e
      Rails.logger.warn "AI feedback generation failed: #{e.message}"
      nil
    end
  end

  def generate_ai_enhanced_event_feedback(event, team)
    return nil unless ai_service_available?

    begin
      ai_service = GoogleAiService.new

      # Create a mock settlement offer for AI context
      mock_offer = build_event_context_offer(team, event)
      ai_response = ai_service.generate_settlement_feedback(mock_offer)

      {
        feedback_text: adapt_event_feedback(ai_response[:feedback_text], event),
        mood_level: ai_response[:mood_level],
        satisfaction_score: ai_response[:satisfaction_score],
        source: "ai"
      }
    rescue => e
      Rails.logger.warn "AI event feedback generation failed: #{e.message}"
      nil
    end
  end

  def generate_ai_enhanced_transition_feedback(team, from_round, to_round, themes)
    return nil unless ai_service_available?

    begin
      ai_service = GoogleAiService.new
      analysis = ai_service.analyze_negotiation_state(simulation, to_round)

      if analysis && analysis[:advice]
        {
          feedback_text: adapt_transition_feedback(analysis[:advice], themes, team),
          mood_level: infer_mood_from_themes(themes),
          satisfaction_score: calculate_satisfaction_from_themes(themes),
          source: "ai"
        }
      end
    rescue => e
      Rails.logger.warn "AI transition feedback generation failed: #{e.message}"
      nil
    end
  end

  def ai_service_available?
    GoogleAI.enabled?
  rescue
    false
  end

  def build_event_context_offer(team, event)
    # Create a contextual offer for AI processing
    recent_round = simulation.negotiation_rounds.order(:round_number).last
    recent_round ||= simulation.negotiation_rounds.build(round_number: 1)

    # Estimate an amount based on team role and event
    estimated_amount = estimate_contextual_amount(team, event)

    OpenStruct.new(
      team: team,
      negotiation_round: recent_round,
      amount: estimated_amount,
      justification: "Event-driven context for #{event.event_type}"
    )
  end

  def estimate_contextual_amount(team, event)
    team_role = determine_team_role(team)

    case team_role
    when "plaintiff"
      base_amount = (simulation.plaintiff_min_acceptable + simulation.plaintiff_ideal) / 2
      adjust_amount_for_event(base_amount, event, team_role)
    when "defendant"
      base_amount = (simulation.defendant_ideal + simulation.defendant_max_acceptable) / 2
      adjust_amount_for_event(base_amount, event, team_role)
    else
      200_000 # Default fallback
    end
  end

  def adjust_amount_for_event(base_amount, event, team_role)
    case event.event_type
    when "media_attention"
      (team_role == "plaintiff") ? base_amount * 1.1 : base_amount * 1.05
    when "additional_evidence"
      (team_role == "plaintiff") ? base_amount * 1.15 : base_amount * 1.1
    when "ipo_delay"
      (team_role == "defendant") ? base_amount * 1.2 : base_amount
    else
      base_amount
    end
  end

  def adapt_event_feedback(ai_text, event)
    # Inject event context into AI response
    event_context = case event.event_type
    when "media_attention"
      "recent media developments"
    when "additional_evidence"
      "new evidence emergence"
    when "ipo_delay"
      "market timing considerations"
    else
      "recent developments"
    end

    # Prepend context if not already present
    if ai_text.downcase.include?(event_context.split.first)
      ai_text
    else
      "Given #{event_context}, #{ai_text.downcase}"
    end
  end

  def adapt_transition_feedback(ai_advice, themes, team)
    team_role = determine_team_role(team)

    # Customize AI advice for specific team role and themes
    role_context = (team_role == "plaintiff") ? "client's position" : "company's exposure"

    if themes.include?(:close_to_settlement)
      "#{ai_advice} The #{role_context} suggests we're approaching a viable resolution."
    elsif themes.include?(:far_from_settlement)
      "#{ai_advice} Significant gaps remain in the #{role_context} that require strategic attention."
    else
      ai_advice
    end
  end

  def infer_mood_from_themes(themes)
    if themes.include?(:settlement_reached)
      "very_satisfied"
    elsif themes.include?(:close_to_settlement) || themes.include?(:high_quality_arguments)
      "satisfied"
    elsif themes.include?(:far_from_settlement) || themes.include?(:low_quality_arguments)
      "unhappy"
    else
      "neutral"
    end
  end

  def calculate_satisfaction_from_themes(themes)
    base_score = 60

    if themes.include?(:settlement_reached)
      base_score = 95
    elsif themes.include?(:high_quality_arguments)
      base_score += 15
    elsif themes.include?(:good_positioning)
      base_score += 10
    elsif themes.include?(:close_to_settlement)
      base_score += 20
    elsif themes.include?(:low_quality_arguments)
      base_score -= 15
    elsif themes.include?(:poor_positioning)
      base_score -= 10
    elsif themes.include?(:far_from_settlement)
      base_score -= 20
    end

    base_score.clamp(0, 100)
  end

  def generate_ai_enhanced_settlement_feedback(team_offer, settlement_amount, role)
    return nil unless ai_service_available?

    begin
      ai_service = GoogleAiService.new
      ai_response = ai_service.generate_settlement_feedback(team_offer)

      # Enhance response with settlement context
      enhanced_text = adapt_settlement_feedback(ai_response[:feedback_text], settlement_amount, role)

      {
        feedback_text: enhanced_text,
        mood_level: ai_response[:mood_level],
        satisfaction_score: ai_response[:satisfaction_score],
        source: "ai"
      }
    rescue => e
      Rails.logger.warn "AI settlement satisfaction feedback generation failed: #{e.message}"
      nil
    end
  end

  def adapt_settlement_feedback(ai_text, settlement_amount, role)
    # Add settlement completion context to AI response
    settlement_context = if role == "plaintiff"
      "With the settlement reached at #{ActionView::Helpers::NumberHelper.number_to_currency(settlement_amount)}, #{ai_text.downcase}"
    else
      "The settlement resolution at #{ActionView::Helpers::NumberHelper.number_to_currency(settlement_amount)} represents #{ai_text.downcase}"
    end

    # Ensure settlement context is added appropriately
    if ai_text.downcase.include?("settlement")
      ai_text
    else
      settlement_context
    end
  end
end
