# frozen_string_literal: true

class GoogleAiService
  include ActionView::Helpers::NumberHelper

  def initialize
    @enabled = GoogleAI.enabled?
    @monitoring_service = AiUsageMonitoringService.new
    begin
      @client = GoogleAI.client if @enabled
      @model = GoogleAI.model
    rescue => e
      Rails.logger.warn "GoogleAI client initialization failed: #{e.message}"
      @enabled = false
      @client = nil
      @model = nil
    end
  end

  # Generate AI-powered feedback for settlement offers with caching
  def generate_settlement_feedback(settlement_offer)
    return fallback_feedback(settlement_offer) unless enabled?

    # Use caching service if available
    if use_caching?(settlement_offer)
      cache_service = AiResponseCacheService.new(settlement_offer.negotiation_round.simulation)

      cache_service.get_or_generate_response(settlement_offer) do
        generate_fresh_settlement_feedback(settlement_offer)
      end
    else
      generate_fresh_settlement_feedback(settlement_offer)
    end
  end

  # Generate fresh AI feedback (without caching)
  def generate_fresh_settlement_feedback(settlement_offer)
    # Check rate limits and budget before making request
    rate_limit_check = @monitoring_service.check_rate_limit
    budget_check = @monitoring_service.check_budget_limit

    unless rate_limit_check[:allowed] && budget_check[:allowed]
      Rails.logger.warn "AI request blocked: Rate limit: #{rate_limit_check[:allowed]}, Budget: #{budget_check[:allowed]}"
      return fallback_feedback(settlement_offer).merge(
        blocked_reason: rate_limit_check[:allowed] ? "budget_exceeded" : "rate_limited"
      )
    end

    start_time = Time.current

    begin
      prompt = build_settlement_prompt_with_personality(settlement_offer)
      response = @client.generate_content(
        {
          contents: {
            parts: {
              text: prompt
            }
          },
          generationConfig: {
            temperature: 0.7,
            topP: 0.8,
            topK: 40,
            maxOutputTokens: 500
          }
        }
      )

      response_time = ((Time.current - start_time) * 1000).round
      response_text = extract_text_from_response(response)
      cost = calculate_cost(response)

      # Track usage
      @monitoring_service.track_request(
        model: @model,
        cost: cost,
        response_time: response_time,
        tokens_used: estimate_tokens_used(prompt, response_text),
        request_type: "settlement_feedback",
        error_occurred: false
      )

      result = parse_ai_feedback_with_personality(response_text, settlement_offer).merge(
        source: "ai",
        cost: cost,
        model_used: @model,
        response_time: response_time
      )

      # Track personality consistency if personality is present
      track_personality_consistency(settlement_offer, result)

      result
    rescue => e
      response_time = ((Time.current - start_time) * 1000).round
      Rails.logger.error "GoogleAI error in generate_settlement_feedback: #{e.message}"

      # Track failed request
      @monitoring_service.track_request(
        model: @model,
        cost: 0,
        response_time: response_time,
        tokens_used: 0,
        request_type: "settlement_feedback",
        error_occurred: true
      )

      error_attributes = {error_handled: true, error_type: e.class.name}

      # Add specific error indicators based on error type
      if e.message.include?("Rate limit")
        error_attributes[:rate_limited] = true
      elsif e.is_a?(Timeout::Error)
        error_attributes[:network_error] = true
      end

      fallback_feedback(settlement_offer).merge(error_attributes)
    end
  end

  # Analyze overall negotiation state and provide strategic guidance
  def analyze_negotiation_state(simulation, current_round)
    return fallback_analysis(simulation, current_round) unless enabled?

    begin
      prompt = build_analysis_prompt(simulation, current_round)
      response = @client.generate_content(
        {
          contents: {
            parts: {
              text: prompt
            }
          },
          generationConfig: {
            temperature: 0.6,
            topP: 0.9,
            maxOutputTokens: 400
          }
        }
      )

      response_text = extract_text_from_response(response)

      {
        advice: response_text,
        round_context: current_round,
        source: "ai",
        confidence: extract_confidence(response_text),
        timestamp: Time.current
      }
    rescue => e
      Rails.logger.error "GoogleAI error in analyze_negotiation_state: #{e.message}"
      fallback_analysis(simulation, current_round)
    end
  end

  # Analyze settlement options for large gaps with caching
  def analyze_settlement_options(plaintiff_offer, defendant_offer)
    return fallback_settlement_options(plaintiff_offer, defendant_offer) unless enabled?

    # Use caching service if available
    if use_gap_caching?(plaintiff_offer, defendant_offer)
      cache_service = AiResponseCacheService.new(extract_simulation(plaintiff_offer, defendant_offer))

      cache_service.get_or_generate_gap_analysis(plaintiff_offer.amount, defendant_offer.amount) do
        generate_fresh_settlement_options(plaintiff_offer, defendant_offer)
      end
    else
      generate_fresh_settlement_options(plaintiff_offer, defendant_offer)
    end
  end

  # Generate fresh settlement options analysis (without caching)
  def generate_fresh_settlement_options(plaintiff_offer, defendant_offer)
    prompt = build_settlement_options_prompt(plaintiff_offer, defendant_offer)
    response = @client.generate_content(
      {
        contents: {
          parts: {
            text: prompt
          }
        },
        generationConfig: {
          temperature: 0.8,
          topP: 0.9,
          maxOutputTokens: 600
        }
      }
    )

    response_text = extract_text_from_response(response)
    parse_settlement_options(response_text, plaintiff_offer, defendant_offer)
  rescue => e
    Rails.logger.error "GoogleAI error in analyze_settlement_options: #{e.message}"
    fallback_settlement_options(plaintiff_offer, defendant_offer)
  end

  # Check if AI service is enabled and available
  def enabled?
    @enabled && GoogleAI.enabled? && @monitoring_service.ai_services_enabled?
  end

  # Fallback feedback when AI is unavailable
  def fallback_feedback(settlement_offer)
    team_role = determine_team_role(settlement_offer.team, settlement_offer.negotiation_round.simulation)
    amount = settlement_offer.amount
    round = settlement_offer.negotiation_round.round_number

    {
      feedback_text: generate_rule_based_feedback(team_role, amount, round),
      mood_level: determine_rule_based_mood(team_role, amount),
      satisfaction_score: calculate_rule_based_satisfaction(team_role, amount),
      strategic_guidance: provide_rule_based_guidance(team_role, round),
      source: "fallback",
      cost: 0,
      timestamp: Time.current
    }
  end

  private

  # Build contextual prompt for settlement feedback with personality
  def build_settlement_prompt_with_personality(settlement_offer)
    simulation = settlement_offer.negotiation_round.simulation
    team_role = determine_team_role(settlement_offer.team, simulation)
    personality_type = get_client_personality(simulation.case, team_role)

    if personality_type.present?
      PersonalityService.build_personality_prompt(settlement_offer, personality_type, team_role)
    else
      build_settlement_prompt(settlement_offer)
    end
  end

  # Legacy method for backward compatibility
  def build_settlement_prompt(settlement_offer)
    simulation = settlement_offer.negotiation_round.simulation
    team_role = determine_team_role(settlement_offer.team, simulation)
    amount_formatted = number_to_currency(settlement_offer.amount)
    round = settlement_offer.negotiation_round.round_number

    <<~PROMPT
      You are providing client feedback in a legal education simulation for business law students.

      Context:
      - This is a sexual harassment lawsuit negotiation simulation
      - Team role: #{team_role}
      - Settlement offer: #{amount_formatted}
      - Negotiation round: #{round}
      - This is for educational purposes to help students understand legal negotiation dynamics

      Please provide realistic client feedback that:
      1. Responds to the settlement amount from the client's perspective
      2. Includes emotional context (satisfaction/concern level)
      3. Provides strategic guidance for the next steps
      4. Maintains educational value while being realistic

      Keep the response professional, educational, and under 150 words.
      Focus on the client's business and legal considerations.
    PROMPT
  end

  # Build prompt for strategic negotiation analysis
  def build_analysis_prompt(simulation, current_round)
    recent_offers = get_recent_offers(simulation, current_round)

    <<~PROMPT
      You are analyzing a negotiation in progress for a legal education simulation.

      Context:
      - Sexual harassment lawsuit negotiation
      - Current round: #{current_round}
      - Recent offers: #{format_offers_for_prompt(recent_offers)}

      Provide strategic analysis that:
      1. Assesses current negotiation dynamics
      2. Identifies potential paths forward
      3. Suggests tactical considerations for both sides
      4. Maintains educational focus for business law students

      Keep analysis concise and actionable, under 200 words.
    PROMPT
  end

  # Build prompt for settlement options analysis
  def build_settlement_options_prompt(plaintiff_offer, defendant_offer)
    gap = plaintiff_offer.amount - defendant_offer.amount
    gap_formatted = number_to_currency(gap)

    <<~PROMPT
      You are analyzing settlement options for a legal education simulation with a large gap.

      Current situation:
      - Plaintiff offer: #{number_to_currency(plaintiff_offer.amount)}
      - Defendant offer: #{number_to_currency(defendant_offer.amount)}
      - Gap: #{gap_formatted}

      Suggest creative settlement approaches that:
      1. Address the large monetary gap
      2. Include non-monetary terms
      3. Consider structured payment options
      4. Assess risks for both parties
      5. Provide educational value for business law students

      Format response with clear sections for creative options and risk assessment.
    PROMPT
  end

  # Parse AI response into structured feedback with personality influence
  def parse_ai_feedback_with_personality(ai_text, settlement_offer)
    simulation = settlement_offer.negotiation_round.simulation
    team_role = determine_team_role(settlement_offer.team, simulation)
    personality_type = get_client_personality(simulation.case, team_role)

    base_mood = determine_mood_from_text(ai_text)
    base_satisfaction = extract_satisfaction_score(ai_text)

    # Apply personality influence if personality is present
    if personality_type.present?
      mood_level = PersonalityService.get_mood_adjustment(
        personality_type,
        base_mood,
        context: determine_offer_context(settlement_offer, team_role)
      )

      satisfaction_score = PersonalityService.personality_influences_satisfaction(
        personality_type,
        base_satisfaction,
        amount: settlement_offer.amount,
        role: team_role
      )
    else
      mood_level = base_mood
      satisfaction_score = base_satisfaction
    end

    {
      feedback_text: ai_text,
      mood_level: mood_level,
      satisfaction_score: satisfaction_score,
      strategic_guidance: extract_strategic_guidance(ai_text),
      sentiment_analysis: analyze_sentiment(ai_text),
      personality_type: personality_type,
      personality_influenced: personality_type.present?
    }
  end

  # Legacy method for backward compatibility
  def parse_ai_feedback(ai_text, settlement_offer)
    {
      feedback_text: ai_text,
      mood_level: determine_mood_from_text(ai_text),
      satisfaction_score: extract_satisfaction_score(ai_text),
      strategic_guidance: extract_strategic_guidance(ai_text),
      sentiment_analysis: analyze_sentiment(ai_text)
    }
  end

  # Parse settlement options response
  def parse_settlement_options(ai_text, plaintiff_offer, defendant_offer)
    {
      creative_options: extract_creative_options(ai_text),
      risk_assessment: extract_risk_assessment(ai_text),
      gap_analysis: {
        gap_size: plaintiff_offer.amount - defendant_offer.amount,
        percentage_gap: calculate_percentage_gap(plaintiff_offer.amount, defendant_offer.amount)
      },
      plaintiff_perspective: extract_role_perspective(ai_text, "plaintiff"),
      defendant_perspective: extract_role_perspective(ai_text, "defendant"),
      source: "ai"
    }
  end

  # Determine mood level from AI text response
  def determine_mood_from_text(text)
    text_lower = text.downcase

    case text_lower
    when /very pleased|extremely satisfied|excellent|outstanding/
      "very_satisfied"
    when /pleased|satisfied|good|positive|acceptable/
      "satisfied"
    when /concerned|worried|disappointed|unhappy|poor/
      "unhappy"
    when /very concerned|very disappointed|unacceptable|terrible/
      "very_unhappy"
    else
      "neutral"
    end
  end

  # Extract satisfaction score from text (1-100)
  def extract_satisfaction_score(text)
    mood = determine_mood_from_text(text)

    case mood
    when "very_satisfied" then rand(85..95)
    when "satisfied" then rand(70..84)
    when "neutral" then rand(50..69)
    when "unhappy" then rand(30..49)
    when "very_unhappy" then rand(10..29)
    else 50
    end
  end

  # Extract strategic guidance from AI response
  def extract_strategic_guidance(text)
    # Look for guidance-related sentences
    sentences = text.split(/[.!?]/)
    guidance_sentences = sentences.select do |sentence|
      sentence.downcase.match?(/consider|suggest|recommend|should|might|could|strategy|approach/)
    end

    guidance_sentences.first&.strip || "Continue monitoring negotiation progress."
  end

  # Analyze sentiment of the response
  def analyze_sentiment(text)
    positive_words = %w[pleased satisfied good excellent positive acceptable pleased]
    negative_words = %w[concerned worried disappointed unhappy poor unacceptable terrible]

    text_words = text.downcase.split
    positive_count = positive_words.count { |word| text_words.include?(word) }
    negative_count = negative_words.count { |word| text_words.include?(word) }

    if positive_count > negative_count
      "positive"
    elsif negative_count > positive_count
      "negative"
    else
      "neutral"
    end
  end

  # Extract confidence level from AI response
  def extract_confidence(text)
    if text.match?(/clearly|definitely|certainly|strongly/)
      "high"
    elsif text.match?(/probably|likely|appears|seems/)
      "medium"
    else
      "low"
    end
  end

  # Fallback analysis when AI is unavailable
  def fallback_analysis(simulation, current_round)
    {
      advice: "Continue strategic positioning based on negotiation fundamentals for round #{current_round}.",
      round_context: current_round,
      source: "fallback",
      confidence: "medium",
      timestamp: Time.current
    }
  end

  # Fallback settlement options analysis
  def fallback_settlement_options(plaintiff_offer, defendant_offer)
    gap = plaintiff_offer.amount - defendant_offer.amount

    {
      creative_options: ["Consider structured payment terms", "Explore non-monetary agreements", "Evaluate performance-based milestones"],
      risk_assessment: "Large gap presents settlement challenges requiring creative solutions",
      gap_analysis: {
        gap_size: gap,
        percentage_gap: calculate_percentage_gap(plaintiff_offer.amount, defendant_offer.amount)
      },
      plaintiff_perspective: "Focus on achieving acceptable compensation through flexible terms",
      defendant_perspective: "Minimize financial exposure while reaching resolution",
      source: "fallback"
    }
  end

  # Helper methods for rule-based fallbacks
  def generate_rule_based_feedback(team_role, amount, round)
    if team_role == "plaintiff"
      "Client reviewing settlement offer of #{number_to_currency(amount)} for round #{round}. Considering strategic positioning for next steps."
    else
      "Client evaluating settlement exposure of #{number_to_currency(amount)} in round #{round}. Assessing acceptable resolution parameters."
    end
  end

  def determine_rule_based_mood(team_role, amount)
    # Simple rule-based mood determination
    # In a real implementation, this would consider simulation ranges
    case amount
    when 0..50_000 then (team_role == "defendant") ? "satisfied" : "unhappy"
    when 50_001..150_000 then "neutral"
    when 150_001..300_000 then (team_role == "plaintiff") ? "satisfied" : "unhappy"
    else (team_role == "plaintiff") ? "very_satisfied" : "very_unhappy"
    end
  end

  def calculate_rule_based_satisfaction(team_role, amount)
    mood = determine_rule_based_mood(team_role, amount)
    case mood
    when "very_satisfied" then 90
    when "satisfied" then 75
    when "neutral" then 50
    when "unhappy" then 35
    when "very_unhappy" then 20
    else 50
    end
  end

  def provide_rule_based_guidance(team_role, round)
    if round <= 2
      "Early negotiation phase - establish strong foundation for your position."
    elsif round <= 4
      "Mid-negotiation - consider flexibility and creative terms."
    else
      "Late negotiation - focus on resolution and final strategic decisions."
    end
  end

  # Utility methods
  def determine_team_role(team, simulation)
    case_team = simulation.case.case_teams.find_by(team: team)
    case_team&.role || "unknown"
  end

  def get_recent_offers(simulation, current_round)
    simulation.settlement_offers
      .joins(:negotiation_round)
      .where(negotiation_rounds: {round_number: [current_round - 1, current_round].max(1)})
      .includes(:team, :negotiation_round)
  end

  def format_offers_for_prompt(offers)
    offers.map do |offer|
      team_role = determine_team_role(offer.team, offer.negotiation_round.simulation)
      "#{team_role}: #{number_to_currency(offer.amount)}"
    end.join(", ")
  end

  def calculate_cost(response)
    # Placeholder for actual cost calculation based on token usage
    # This would integrate with Google AI billing metrics
    0
  end

  def calculate_percentage_gap(amount1, amount2)
    return 0 if amount2.zero?
    ((amount1 - amount2).abs / amount2.to_f * 100).round(2)
  end

  def extract_creative_options(text)
    # Extract numbered or bulleted lists of options
    options = text.scan(/\d+\)\s*([^\n\d]+)/).flatten
    options = text.scan(/[-•]\s*([^\n-•]+)/).flatten if options.empty?
    options = options.map(&:strip).reject(&:empty?)

    # If no structured options found, return default fallback options
    if options.empty?
      ["Consider structured payment terms", "Explore non-monetary agreements", "Evaluate performance-based milestones"]
    else
      options
    end
  end

  def extract_risk_assessment(text)
    # Look for risk-related content
    risk_sentences = text.split(/[.!?]/).select do |sentence|
      sentence.downcase.match?(/risk|challenge|concern|danger|uncertainty/)
    end
    risk_sentences.first&.strip || "Standard negotiation risks apply"
  end

  def extract_role_perspective(text, role)
    # Extract content relevant to specific role
    role_sentences = text.split(/[.!?]/).select do |sentence|
      sentence.downcase.include?(role)
    end
    role_sentences.first&.strip || "Consider role-specific strategic approaches"
  end

  # Extract text content from Gemini response
  def extract_text_from_response(response)
    response.dig("candidates", 0, "content", "parts", 0, "text")&.strip || ""
  end

  # Caching helper methods

  def use_caching?(settlement_offer)
    # Enable caching for settlement feedback if:
    # 1. Caching is enabled globally
    # 2. Settlement offer has sufficient context
    # 3. Not in development/test mode (optional)
    caching_enabled? && settlement_offer.respond_to?(:negotiation_round) &&
      settlement_offer.negotiation_round.respond_to?(:simulation)
  rescue
    false
  end

  def use_gap_caching?(plaintiff_offer, defendant_offer)
    # Enable caching for gap analysis if both offers have context
    caching_enabled? &&
      extract_simulation(plaintiff_offer, defendant_offer) &&
      plaintiff_offer.respond_to?(:amount) &&
      defendant_offer.respond_to?(:amount)
  rescue
    false
  end

  def caching_enabled?
    # Check if AI response caching is enabled
    Rails.application.config.respond_to?(:ai_response_caching) &&
      Rails.application.config.ai_response_caching
  rescue
    false
  end

  def extract_simulation(plaintiff_offer, defendant_offer)
    # Extract simulation from either offer
    simulation = plaintiff_offer&.negotiation_round&.simulation ||
      defendant_offer&.negotiation_round&.simulation

    # If offers are mock objects (like OpenStruct), try different approach
    simulation ||= plaintiff_offer&.simulation || defendant_offer&.simulation

    simulation
  end

  # Personality-related helper methods
  def get_client_personality(case_instance, team_role)
    case team_role
    when "plaintiff"
      case_instance.plaintiff_info["personality_type"]
    when "defendant"
      case_instance.defendant_info["personality_type"]
    end
  end

  def determine_offer_context(settlement_offer, team_role)
    amount = settlement_offer.amount

    # Simple context determination based on amount ranges
    # In a real system, this would be more sophisticated
    case team_role
    when "plaintiff"
      case amount
      when 0..75_000 then "low_offer"
      when 75_001..200_000 then "reasonable_offer"
      else "positive_offer"
      end
    when "defendant"
      case amount
      when 0..100_000 then "positive_offer"
      when 100_001..250_000 then "reasonable_offer"
      else "negative_offer"
      end
    else
      "neutral_offer"
    end
  end

  def track_personality_consistency(settlement_offer, result)
    return unless result[:personality_type].present?

    simulation = settlement_offer.negotiation_round.simulation
    case_instance = simulation.case

    # Get recent responses for this case and personality
    recent_trackers = PersonalityConsistencyTracker
      .where(case: case_instance, personality_type: result[:personality_type])
      .recent
      .limit(1)
      .first

    if recent_trackers
      # Update existing tracker with new response
      updated_history = recent_trackers.response_history + [result[:feedback_text]]
      recent_trackers.update!(
        response_history: updated_history,
        consistency_score: PersonalityService.send(:calculate_consistency_score,
          result[:personality_type],
          updated_history)
      )
    else
      # Create new tracker
      PersonalityService.track_consistency(
        case_instance,
        result[:personality_type],
        [result[:feedback_text]]
      )
    end
  rescue => e
    Rails.logger.warn "Failed to track personality consistency: #{e.message}"
  end

  def estimate_tokens_used(prompt, response_text)
    # Rough estimation: 1 token ≈ 0.75 words
    # This is an approximation for monitoring purposes
    word_count = (prompt.split.length + response_text.split.length)
    (word_count / 0.75).round
  end
end
