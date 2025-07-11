# frozen_string_literal: true

class NegotiationsController < ApplicationController
  include ImpersonationReadOnly

  before_action :authenticate_user!
  before_action :set_case
  before_action :set_simulation
  before_action :verify_team_participation
  before_action :set_current_round, except: [:history, :templates, :calculator]

  def index
    @negotiation_rounds = @simulation.negotiation_rounds
      .includes(:settlement_offers)
      .by_round_number
    @current_team_offer = current_team_offer_for_round(@current_round)
    @current_opposing_offer = opposing_offer_for_round(@current_round) if @current_round
    @opposing_team_offers = opposing_team_offers
    @client_mood = fetch_client_mood
    @pressure_status = fetch_pressure_status
  end

  def show
    @negotiation_round = @simulation.negotiation_rounds.find(params[:id])
    @team_offer = @negotiation_round.settlement_offers.find_by(team: current_user_team)
    @opposing_offer = opposing_offer_for_round(@negotiation_round)
    @client_feedback = fetch_client_feedback(@negotiation_round)
  end

  def submit_offer
    @settlement_offer = build_new_settlement_offer
    @argument_templates = load_argument_templates
    @non_monetary_options = load_non_monetary_options
    @client_consultation = fetch_client_consultation_data
  end

  def create_offer
    @settlement_offer = build_new_settlement_offer

    if params[:consult_client]
      # Pass the settlement offer data to the consultation page
      consultation_params = offer_params.to_h if offer_params
      redirect_to client_consultation_case_negotiation_path(@case, @current_round, settlement_offer: consultation_params)
      return
    end

    if submit_offer_via_api
      redirect_to case_negotiations_path(@case),
        notice: "Settlement offer submitted successfully!"
    else
      @argument_templates = load_argument_templates
      @non_monetary_options = load_non_monetary_options
      flash.now[:alert] = "Please correct the errors below"
      render :submit_offer, status: :unprocessable_entity
    end
  end

  def counter_offer
    @original_offer = find_opposing_team_latest_offer
    unless @original_offer
      redirect_to case_negotiations_path(@case),
        alert: "No opposing offer found to respond to"
      return
    end

    @settlement_offer = build_counter_offer_response
    @argument_templates = load_argument_templates
    @non_monetary_options = load_non_monetary_options
  end

  def submit_counter_offer
    @original_offer = find_opposing_team_latest_offer
    @settlement_offer = build_counter_offer_response

    if submit_offer_via_api
      redirect_to case_negotiations_path(@case),
        notice: "Counter-offer submitted successfully!"
    else
      @argument_templates = load_argument_templates
      @non_monetary_options = load_non_monetary_options
      flash.now[:alert] = "Please correct the errors below"
      render :counter_offer, status: :unprocessable_entity
    end
  end

  def client_consultation
    @settlement_offer = build_new_settlement_offer
    @client_data = fetch_detailed_client_consultation

    # Get proposed offer from params (passed from create_offer when consulting client)
    if params[:settlement_offer]
      @proposed_offer = params[:settlement_offer].is_a?(ActionController::Parameters) ?
                        params[:settlement_offer].permit(:amount, :justification, :non_monetary_terms) :
                        params[:settlement_offer]
    end

    # Ensure we have a proposed offer for the client reaction functionality
    @proposed_offer ||= {amount: 100000} # Default amount for demo purposes
  end

  def consult_client
    @client_feedback = perform_client_consultation

    if params[:proceed_with_offer]
      if submit_offer_via_api
        redirect_to case_negotiations_path(@case),
          notice: "Offer submitted after client consultation!"
      else
        @settlement_offer = build_new_settlement_offer
        @client_data = fetch_detailed_client_consultation
        flash.now[:alert] = "Please correct the errors below"
        render :client_consultation, status: :unprocessable_entity
      end
    else
      redirect_to submit_offer_case_negotiation_path(@case, @current_round),
        notice: "Client consultation completed. You can modify your offer."
    end
  end

  def history
    @all_rounds = @simulation.negotiation_rounds
      .includes(settlement_offers: [:team, :submitted_by])
      .by_round_number
    @negotiation_timeline = build_negotiation_timeline
    @settlement_analysis = analyze_settlement_progress
  end

  def templates
    @templates = {
      legal_precedent: load_legal_precedent_template,
      economic_damages: load_economic_damages_template,
      risk_assessment: load_risk_assessment_template,
      client_impact: load_client_impact_template
    }

    render json: @templates if request.xhr?
  end

  def calculator
    @damage_categories = load_damage_calculation_categories
    @case_specific_data = load_case_calculation_data

    if request.post?
      @calculation_results = perform_damage_calculation
      render json: @calculation_results if request.xhr?
    end
  end

  def ai_client_reaction
    # Get proposed offer data
    proposed_offer_data = {
      amount: params[:amount]&.to_f,
      justification: params[:justification],
      non_monetary_terms: params[:non_monetary_terms]
    }

    # Validate amount
    if proposed_offer_data[:amount].nil? || proposed_offer_data[:amount] <= 0
      render json: {
        error: "Invalid settlement amount",
        fallback: generate_fallback_reaction(100000)
      }, status: :bad_request
      return
    end

    # Create a mock settlement offer for AI service
    mock_offer = OpenStruct.new(
      amount: proposed_offer_data[:amount],
      justification: proposed_offer_data[:justification],
      non_monetary_terms: proposed_offer_data[:non_monetary_terms],
      team: current_user_team,
      negotiation_round: OpenStruct.new(
        round_number: @current_round,
        simulation: @simulation
      )
    )

    # Get AI-powered client reaction
    ai_service = GoogleAiService.new
    if ai_service.enabled?
      ai_feedback = ai_service.generate_settlement_feedback(mock_offer)

      # Convert AI feedback to client reaction format
      reaction_data = {
        reaction: map_ai_mood_to_reaction(ai_feedback[:mood_level]),
        message: ai_feedback[:feedback_text],
        mood_level: ai_feedback[:mood_level],
        satisfaction_score: ai_feedback[:satisfaction_score],
        strategic_guidance: ai_feedback[:strategic_guidance],
        source: "ai",
        cost: ai_feedback[:cost],
        response_time: ai_feedback[:response_time]
      }
    else
      # Fall back to rule-based consultation if AI is unavailable
      reaction_data = generate_fallback_reaction(proposed_offer_data[:amount])
      reaction_data[:source] = "fallback"
    end

    render json: {reaction: reaction_data}
  rescue => e
    Rails.logger.error "Error in ai_client_reaction: #{e.message}"
    render json: {
      error: "Failed to generate client reaction",
      fallback: generate_fallback_reaction(params[:amount]&.to_f || 100000)
    }, status: :internal_server_error
  end

  private

  def set_case
    @case = Case.find(params[:case_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to cases_path, alert: "Case not found"
  end

  def set_simulation
    @simulation = @case.active_simulation

    unless @simulation
      redirect_to cases_path,
        alert: "This case does not have an active simulation"
    end
  end

  def verify_team_participation
    unless current_user_team
      redirect_to cases_path,
        alert: "You are not assigned to a team for this case"
      return
    end

    unless @simulation.teams.include?(current_user_team)
      redirect_to cases_path,
        alert: "Your team is not participating in this simulation"
    end
  end

  def set_current_round
    @current_round = @simulation.negotiation_rounds
      .find_by(round_number: @simulation.current_round) ||
      create_current_round
  end

  def current_user_team
    @current_user_team ||= current_user.teams
      .joins(simulation: :case)
      .where(simulations: {case_id: @case.id})
      .first
  end

  def create_current_round
    deadline = 48.hours.from_now # Default 48 hours

    @simulation.negotiation_rounds.create!(
      round_number: @simulation.current_round,
      deadline: deadline,
      status: :active
    )
  end

  def current_team_offer_for_round(round)
    return nil unless round

    round.settlement_offers.find_by(team: current_user_team)
  end

  def opposing_team_offers
    opposing_team = find_opposing_team

    @simulation.negotiation_rounds
      .joins(:settlement_offers)
      .where(settlement_offers: {team: opposing_team})
      .includes(:settlement_offers)
      .by_round_number
  end

  def opposing_offer_for_round(round)
    opposing_team = find_opposing_team

    round.settlement_offers.find_by(team: opposing_team)
  end

  def find_opposing_team_latest_offer
    opposing_team = find_opposing_team

    SettlementOffer.joins(:negotiation_round)
      .where(team: opposing_team)
      .where(negotiation_rounds: {simulation: @simulation})
      .order("negotiation_rounds.round_number DESC, settlement_offers.submitted_at DESC")
      .first
  end

  def build_new_settlement_offer
    SettlementOffer.new(offer_params).tap do |offer|
      offer.negotiation_round = @current_round
      offer.team = current_user_team
      offer.submitted_by = current_user
      offer.submitted_at = Time.current
    end
  end

  def build_counter_offer_response
    SettlementOffer.new(offer_params).tap do |offer|
      offer.negotiation_round = @current_round
      offer.team = current_user_team
      offer.submitted_by = current_user
      offer.submitted_at = Time.current
      offer.offer_type = :counteroffer
    end
  end

  def find_opposing_team
    if current_user_team.role_plaintiff?
      @simulation.defendant_teams.first
    else
      @simulation.plaintiff_teams.first
    end
  end

  def submit_offer_via_api
    return false unless @settlement_offer.valid?

    begin
      response = make_api_request

      if response.success?
        @settlement_offer = parse_api_response(response)
        true
      else
        parse_api_errors(response)
        false
      end
    rescue => e
      @settlement_offer.errors.add(:base, "System error: #{e.message}")
      false
    end
  end

  def make_api_request
    uri = URI("#{request.base_url}/api/cases/#{@case.id}/negotiation_rounds")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{current_user.jwt_token}" if current_user.respond_to?(:jwt_token)

    request.body = {
      settlement_offer: {
        amount: @settlement_offer.amount,
        justification: @settlement_offer.justification,
        non_monetary_terms: @settlement_offer.non_monetary_terms,
        offer_type: @settlement_offer.offer_type
      }
    }.to_json

    http.request(request)
  end

  def parse_api_response(response)
    data = JSON.parse(response.body)
    # Update local settlement offer with response data
    @settlement_offer.assign_attributes(data.dig("data", "attributes") || {})
    @settlement_offer
  end

  def parse_api_errors(response)
    data = JSON.parse(response.body)
    errors = data["errors"] || ["Unknown error occurred"]

    errors.each do |error|
      @settlement_offer.errors.add(:base, error)
    end
  end

  def fetch_client_mood
    # Use proper ClientFeedbackService for consistent mood tracking
    client_feedback_service = ClientFeedbackService.new(@simulation)
    mood_indicator = client_feedback_service.get_client_mood_indicator(current_user_team)

    {
      mood: mood_indicator[:mood_description]&.downcase || "neutral",
      confidence: map_satisfaction_to_confidence(mood_indicator[:satisfaction_level]),
      satisfaction: map_satisfaction_to_score(mood_indicator[:satisfaction_level]),
      pressure_level: calculate_pressure_level,
      mood_emoji: mood_indicator[:mood_emoji],
      trend: mood_indicator[:trend],
      last_updated: mood_indicator[:last_updated]
    }
  end

  def fetch_pressure_status
    {
      timeline_pressure: calculate_timeline_pressure,
      media_pressure: @simulation.simulation_events.where(event_type: "media_attention").count,
      trial_date: @simulation.created_at + 12.weeks,
      current_round: @simulation.current_round,
      total_rounds: @simulation.total_rounds
    }
  end

  def calculate_timeline_pressure
    rounds_remaining = @simulation.total_rounds - @simulation.current_round
    return "Critical" if rounds_remaining <= 1
    return "High" if rounds_remaining <= 2
    return "Medium" if rounds_remaining <= 3
    "Low"
  end

  def calculate_pressure_level
    case calculate_timeline_pressure
    when "Critical" then 5
    when "High" then 4
    when "Medium" then 3
    when "Low" then 2
    else 1
    end
  end

  def map_satisfaction_to_confidence(satisfaction_level)
    case satisfaction_level
    when "Very High" then 9
    when "High" then 8
    when "Moderate" then 6
    when "Low" then 4
    when "Very Low" then 2
    else 5
    end
  end

  def map_satisfaction_to_score(satisfaction_level)
    case satisfaction_level
    when "Very High" then 10
    when "High" then 8
    when "Moderate" then 7
    when "Low" then 5
    when "Very Low" then 2
    else 6
    end
  end

  def fetch_client_feedback(round)
    # Fetch existing client feedback for this round
    round.client_feedbacks.where(team: current_user_team).order(:created_at)
  end

  def fetch_client_consultation_data
    {
      priorities: load_client_priorities,
      concerns: load_client_concerns,
      acceptable_range: load_client_acceptable_range,
      mood_factors: fetch_current_mood_factors
    }
  end

  def load_client_priorities
    if current_user_team == @simulation.plaintiff_team
      [
        {name: "Financial Security", importance: "High", description: "Compensation for damages and future security"},
        {name: "Justice/Accountability", importance: "High", description: "Holding defendant accountable"},
        {name: "Privacy Protection", importance: "Medium", description: "Avoiding public exposure"},
        {name: "Future Employment", importance: "Medium", description: "Protecting career prospects"}
      ]
    else
      [
        {name: "Cost Minimization", importance: "High", description: "Limiting financial exposure"},
        {name: "Reputation Protection", importance: "High", description: "Avoiding negative publicity"},
        {name: "Quick Resolution", importance: "Medium", description: "Resolving matter efficiently"},
        {name: "No Admission", importance: "Medium", description: "Avoiding admission of wrongdoing"}
      ]
    end
  end

  def load_client_concerns
    if current_user_team == @simulation.plaintiff_team
      ["Insufficient compensation", "Lengthy trial process", "Public exposure", "Career impact"]
    else
      ["Excessive settlement demand", "Precedent setting", "Media attention", "Business disruption"]
    end
  end

  def load_client_acceptable_range
    if current_user_team == @simulation.plaintiff_team
      {
        minimum: @simulation.plaintiff_min_acceptable,
        ideal: @simulation.plaintiff_ideal,
        maximum: @simulation.plaintiff_ideal * 1.5
      }
    else
      {
        minimum: @simulation.defendant_ideal * 0.5,
        ideal: @simulation.defendant_ideal,
        maximum: @simulation.defendant_max_acceptable
      }
    end
  end

  def fetch_current_mood_factors
    pressure_level = calculate_timeline_pressure

    factors = []
    factors << "Time pressure increasing" if pressure_level.in?(["High", "Critical"])
    factors << "Media attention growing" if @simulation.simulation_events.where(event_type: "media_attention").exists?
    factors << "Financial pressures mounting" if @simulation.current_round >= 3
    factors << "Trial date approaching" if @simulation.current_round >= 4

    factors
  end

  def perform_client_consultation
    # Simulate client consultation based on proposed offer
    proposed_amount = offer_params[:amount].to_f
    generate_fallback_reaction(proposed_amount)
  end

  private

  def generate_fallback_reaction(proposed_amount)
    if current_user_team == @simulation.plaintiff_team
      if proposed_amount >= @simulation.plaintiff_ideal
        {reaction: "pleased", message: "Client is satisfied with this aggressive position"}
      elsif proposed_amount >= @simulation.plaintiff_min_acceptable
        {reaction: "neutral", message: "Client finds this acceptable but hopes for more"}
      else
        {reaction: "concerned", message: "Client is worried this is too low"}
      end
    elsif proposed_amount <= @simulation.defendant_ideal
      {reaction: "pleased", message: "Client is satisfied with this conservative offer"}
    elsif proposed_amount <= @simulation.defendant_max_acceptable
      {reaction: "neutral", message: "Client accepts this as reasonable business cost"}
    else
      {reaction: "concerned", message: "Client is concerned about this high exposure"}
    end
  end

  def map_ai_mood_to_reaction(mood_level)
    case mood_level
    when "very_satisfied", "satisfied"
      "pleased"
    when "neutral"
      "neutral"
    when "unhappy", "very_unhappy"
      "concerned"
    else
      "neutral"
    end
  end

  def build_negotiation_timeline
    timeline = []

    @simulation.negotiation_rounds.includes(settlement_offers: :team).find_each do |round|
      round.settlement_offers.each do |offer|
        timeline << {
          round: round.round_number,
          team: offer.team.name,
          amount: offer.amount,
          submitted_at: offer.submitted_at,
          offer_type: offer.offer_type
        }
      end
    end

    timeline.sort_by { |item| [item[:round], item[:submitted_at]] }
  end

  def analyze_settlement_progress
    return {} unless @simulation.negotiation_rounds.any?

    latest_round = @simulation.negotiation_rounds.order(:round_number).last
    plaintiff_offer = latest_round.plaintiff_offer
    defendant_offer = latest_round.defendant_offer

    return {} unless plaintiff_offer && defendant_offer

    gap = (plaintiff_offer.amount - defendant_offer.amount).abs
    movement_trend = calculate_movement_trend

    {
      current_gap: gap,
      gap_percentage: (gap / plaintiff_offer.amount * 100).round(1),
      movement_trend: movement_trend,
      settlement_probability: calculate_settlement_probability(gap, movement_trend)
    }
  end

  def calculate_movement_trend
    return "insufficient_data" if @simulation.negotiation_rounds.count < 2

    recent_rounds = @simulation.negotiation_rounds.order(:round_number).last(2)
    return "insufficient_data" unless recent_rounds.all? { |r| r.both_teams_submitted? }

    old_gap = recent_rounds.first.settlement_gap
    new_gap = recent_rounds.last.settlement_gap

    return "converging" if new_gap < old_gap
    return "stable" if new_gap == old_gap
    "diverging"
  end

  def calculate_settlement_probability(gap, trend)
    base_probability = case trend
    when "converging" then 60
    when "stable" then 30
    when "diverging" then 10
    else 25
    end

    # Adjust based on gap size
    if gap < 25000
      base_probability += 30
    elsif gap < 50000
      base_probability += 15
    elsif gap > 200000
      base_probability -= 20
    end

    # Adjust based on round number
    pressure_bonus = (@simulation.current_round - 1) * 5

    (base_probability + pressure_bonus).clamp(5, 95)
  end

  def load_argument_templates
    {
      legal_precedent: load_legal_precedent_template,
      economic_damages: load_economic_damages_template,
      risk_assessment: load_risk_assessment_template,
      client_impact: load_client_impact_template
    }
  end

  def load_legal_precedent_template
    "LEGAL PRECEDENT ANALYSIS:\n\nRelevant Case Law:\n- [Case Name v. Case Name]: $[amount] settlement for [circumstances]\n- [Legal Standard]: [explanation]\n\nStatutory Framework:\n- [Relevant statute]: [key provisions]\n- [Regulatory guidance]: [application]\n\nLegal Risk Assessment:\n- Liability strength: [assessment]\n- Damages calculation: [methodology]\n- Precedent support: [analysis]\n\nCONCLUSION: Based on established precedent, our position is supported by [reasoning]."
  end

  def load_economic_damages_template
    "ECONOMIC DAMAGES ANALYSIS:\n\nLost Wages: $[amount]\nPeriod: [start_date] to [end_date]\nCalculation: [methodology]\n\nFuture Earning Capacity: $[amount]\nBasis: [explanation]\n\nMedical/Therapy Costs: $[amount]\nDocumentation: [reference]\n\nPain and Suffering: $[amount]\nJustification: [explanation]\n\nTOTAL CLAIMED DAMAGES: $[total]"
  end

  def load_risk_assessment_template
    "SETTLEMENT RISK ASSESSMENT:\n\nTrial Risks:\n- Liability exposure: [percentage] chance of [outcome]\n- Damages range: $[low] to $[high]\n- Jury unpredictability: [assessment]\n\nSettlement Benefits:\n- Certainty of outcome: [explanation]\n- Cost savings: $[amount] in legal fees\n- Time savings: [duration] to resolution\n\nRecommendation: [settlement/trial] because [reasoning]"
  end

  def load_client_impact_template
    "CLIENT IMPACT STATEMENT:\n\nPersonal Impact:\n- [Specific harm experienced]\n- [Ongoing effects]\n- [Future implications]\n\nFinancial Impact:\n- Current financial situation: [description]\n- Future needs: [requirements]\n- Settlement necessity: [urgency]\n\nEmotional Factors:\n- [Client's emotional state]\n- [Closure needs]\n- [Justice expectations]\n\nCONCLUSION: This settlement [will/will not] adequately address our client's needs because [reasoning]."
  end

  def load_non_monetary_options
    {
      confidentiality: [
        "Standard confidentiality agreement",
        "Mutual non-disclosure with exceptions",
        "Public statement allowed but limited"
      ],
      admissions: [
        "No admission of wrongdoing",
        "Acknowledgment of policy failures",
        "Full admission of liability"
      ],
      references: [
        "Positive reference letter required",
        "Neutral reference only",
        "No reference commitment"
      ],
      policy_changes: [
        "Mandatory harassment training",
        "Policy revision requirements",
        "Third-party monitoring"
      ],
      other_terms: [
        "Public apology",
        "Charitable donation",
        "Industry reporting"
      ]
    }
  end

  def load_damage_calculation_categories
    [
      {
        category: "Lost Wages",
        fields: ["monthly_salary", "unemployment_months", "benefits_value"],
        calculation: "monthly_salary * unemployment_months + benefits_value"
      },
      {
        category: "Future Earnings",
        fields: ["annual_salary", "years_impacted", "career_advancement_loss"],
        calculation: "annual_salary * years_impacted * career_advancement_loss"
      },
      {
        category: "Medical Costs",
        fields: ["therapy_sessions", "cost_per_session", "medication_costs"],
        calculation: "therapy_sessions * cost_per_session + medication_costs"
      },
      {
        category: "Pain and Suffering",
        fields: ["severity_rating", "duration_months", "impact_multiplier"],
        calculation: "severity_rating * duration_months * impact_multiplier * 1000"
      }
    ]
  end

  def load_case_calculation_data
    # Case-specific data for damage calculations
    {
      plaintiff_salary: 85000,
      unemployment_duration: 8,
      therapy_sessions: 24,
      medical_costs: 3500
    }
  end

  def perform_damage_calculation
    params[:calculation] || {}
  end

  def fetch_detailed_client_consultation
    base_data = fetch_client_consultation_data

    # Add more detailed consultation data for the full consultation page
    base_data.merge({
      previous_consultations: fetch_previous_consultations,
      settlement_history: fetch_settlement_history,
      risk_assessment: fetch_consultation_risk_assessment
    })
  end

  def fetch_previous_consultations
    # Return previous consultation records for this simulation
    []
  end

  def fetch_settlement_history
    # Return historical settlement data for context
    []
  end

  def fetch_consultation_risk_assessment
    # Return detailed risk assessment for client consultation
    {
      trial_risk: "Medium",
      settlement_recommendation: "Proceed with caution",
      financial_impact: "Manageable"
    }
  end

  def offer_params
    if params[:settlement_offer]
      params.require(:settlement_offer).permit(
        :amount,
        :justification,
        :non_monetary_terms,
        :offer_type,
        confidentiality_terms: [],
        admission_terms: [],
        reference_terms: [],
        policy_terms: [],
        other_terms: []
      )
    end
  end
end
