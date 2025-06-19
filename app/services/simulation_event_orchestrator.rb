# frozen_string_literal: true

class SimulationEventOrchestrator
  attr_reader :simulation

  def initialize(simulation)
    @simulation = simulation
  end

  # Main orchestration method called when a round begins
  def orchestrate_round_events!(round_number)
    return [] unless simulation.should_trigger_events?
    return [] if round_number <= 1 # No events in first round

    events_triggered = []

    # Check for scheduled events
    scheduled_events = check_scheduled_events(round_number)
    events_triggered.concat(scheduled_events)

    # Check for dynamic event triggers
    dynamic_events = check_dynamic_event_triggers(round_number)
    events_triggered.concat(dynamic_events)

    # Apply all event effects
    events_triggered.each do |event|
      apply_event_effects!(event)
      generate_event_notifications!(event)
    end

    events_triggered
  end

  # Check for events that should trigger based on simulation state
  def orchestrate_state_based_events!
    events_triggered = []

    # Check for settlement gap triggers
    gap_events = check_settlement_gap_triggers
    events_triggered.concat(gap_events)

    # Check for quality-based triggers
    quality_events = check_argument_quality_triggers
    events_triggered.concat(quality_events)

    # Check for timing-based triggers
    timing_events = check_timing_based_triggers
    events_triggered.concat(timing_events)

    # Apply effects
    events_triggered.each do |event|
      apply_event_effects!(event)
      generate_event_notifications!(event)
    end

    events_triggered
  end

  # Manual event creation for instructor intervention
  def create_custom_event!(event_type, description, pressure_adjustments = {}, metadata = {})
    event = simulation.simulation_events.create!(
      event_type: event_type,
      trigger_round: simulation.current_round,
      triggered_at: Time.current,
      impact_description: description,
      event_data: metadata.merge({
        "custom_event" => true,
        "created_by" => "instructor"
      }),
      pressure_adjustment: pressure_adjustments,
      automatic: false
    )

    apply_event_effects!(event)
    generate_event_notifications!(event)

    event
  end

  # Get pending events that haven't been triggered yet
  def get_pending_events
    simulation.simulation_events.pending.order(:triggered_at)
  end

  # Get events triggered in a specific round
  def get_round_events(round_number)
    simulation.simulation_events
      .where(trigger_round: round_number)
      .triggered
      .order(:triggered_at)
  end

  # Schedule future events
  def schedule_future_events!(target_round, delay_hours = 0)
    scheduled_events = []

    # Schedule context-specific events
    case target_round
    when 2
      if should_schedule_media_event?
        event = schedule_media_attention_event(target_round, delay_hours)
        scheduled_events << event if event
      end
    when 3
      if should_schedule_witness_event?
        event = schedule_witness_change_event(target_round, delay_hours)
        scheduled_events << event if event
      end
    when 4
      if should_schedule_business_pressure_event?
        event = schedule_ipo_delay_event(target_round, delay_hours)
        scheduled_events << event if event
      end
    when 5
      if should_schedule_court_deadline_event?
        event = schedule_court_deadline_event(target_round, delay_hours)
        scheduled_events << event if event
      end
    end

    scheduled_events
  end

  private

  def check_scheduled_events(round_number)
    # Get events that were scheduled for this round and should trigger now
    scheduled = simulation.simulation_events
      .where(trigger_round: round_number)
      .where("triggered_at <= ?", Time.current)
      .where.not(event_data: nil)

    # Filter out already applied events
    scheduled.reject { |event| event.event_data["applied"] == true }
  end

  def check_dynamic_event_triggers(round_number)
    events = []

    # Media attention trigger based on case progress
    if should_trigger_media_attention_now?(round_number)
      event = create_immediate_media_event(round_number)
      events << event if event
    end

    # Witness change based on negotiation difficulty
    if should_trigger_witness_change_now?(round_number)
      event = create_immediate_witness_event(round_number)
      events << event if event
    end

    # Business pressure based on company case type
    if should_trigger_business_pressure_now?(round_number)
      event = create_immediate_business_pressure_event(round_number)
      events << event if event
    end

    events
  end

  def check_settlement_gap_triggers
    current_round = simulation.current_negotiation_round
    return [] unless current_round&.both_teams_submitted?

    gap = current_round.settlement_gap
    return [] unless gap

    events = []

    # Large gap triggers additional pressure
    if gap > simulation.plaintiff_ideal * 0.5
      event = create_gap_pressure_event(gap)
      events << event if event
    end

    events
  end

  def check_argument_quality_triggers
    recent_offers = SettlementOffer.joins(:negotiation_round)
      .where(negotiation_rounds: {simulation: simulation})
      .where("negotiation_rounds.round_number >= ?", simulation.current_round - 1)

    return [] if recent_offers.empty?

    avg_quality = recent_offers.average(:quality_score) || 50
    events = []

    # Very poor argument quality triggers expert testimony event
    if avg_quality < 30
      event = create_expert_testimony_event
      events << event if event
    end

    events
  end

  def check_timing_based_triggers
    events = []

    # Late in negotiation triggers court deadline pressure
    if simulation.current_round >= simulation.total_rounds - 1
      unless simulation.simulation_events.exists?(event_type: :court_deadline)
        event = create_urgent_court_deadline_event
        events << event if event
      end
    end

    events
  end

  # Event creation methods
  def create_immediate_media_event(round_number)
    SimulationEvent.create!(
      simulation: simulation,
      event_type: :media_attention,
      trigger_round: round_number,
      triggered_at: Time.current,
      impact_description: "Breaking: Local news reports on ongoing harassment lawsuit settlement talks",
      event_data: {
        "immediate_trigger" => true,
        "media_intensity" => "high",
        "public_interest" => "significant"
      },
      pressure_adjustment: {
        "plaintiff_min_increase" => 15000,
        "defendant_max_increase" => 40000
      },
      automatic: true
    )
  end

  def create_immediate_witness_event(round_number)
    SimulationEvent.create!(
      simulation: simulation,
      event_type: :witness_change,
      trigger_round: round_number,
      triggered_at: Time.current,
      impact_description: "Development: Former colleague comes forward with corroborating testimony",
      event_data: {
        "immediate_trigger" => true,
        "witness_credibility" => "high",
        "testimony_impact" => "strengthens_plaintiff_case"
      },
      pressure_adjustment: {
        "defendant_max_increase" => 60000
      },
      automatic: true
    )
  end

  def create_immediate_business_pressure_event(round_number)
    SimulationEvent.create!(
      simulation: simulation,
      event_type: :ipo_delay,
      trigger_round: round_number,
      triggered_at: Time.current,
      impact_description: "Company board expresses concern about litigation impact on business operations",
      event_data: {
        "immediate_trigger" => true,
        "business_impact" => "operational_disruption",
        "board_pressure" => "significant"
      },
      pressure_adjustment: {
        "defendant_max_increase" => 75000
      },
      automatic: true
    )
  end

  def create_gap_pressure_event(gap)
    SimulationEvent.create!(
      simulation: simulation,
      event_type: :additional_evidence,
      trigger_round: simulation.current_round,
      triggered_at: Time.current,
      impact_description: "Mediator suggests parties reconsider positions given significant gap in settlement expectations",
      event_data: {
        "trigger_cause" => "large_settlement_gap",
        "gap_amount" => gap,
        "mediator_recommendation" => "increased_flexibility"
      },
      pressure_adjustment: {
        "plaintiff_min_increase" => -gap * 0.1,
        "defendant_max_increase" => gap * 0.15
      },
      automatic: true
    )
  end

  def create_expert_testimony_event
    SimulationEvent.create!(
      simulation: simulation,
      event_type: :expert_testimony,
      trigger_round: simulation.current_round,
      triggered_at: Time.current,
      impact_description: "Employment law expert provides analysis on typical settlement ranges for similar cases",
      event_data: {
        "trigger_cause" => "poor_argument_quality",
        "expert_type" => "employment_law_specialist",
        "analysis_provided" => "settlement_benchmarking"
      },
      pressure_adjustment: {
        "plaintiff_min_increase" => 10000,
        "defendant_max_increase" => 25000
      },
      automatic: true
    )
  end

  def create_urgent_court_deadline_event
    SimulationEvent.create!(
      simulation: simulation,
      event_type: :court_deadline,
      trigger_round: simulation.current_round,
      triggered_at: Time.current,
      impact_description: "Judge sets firm trial date in 14 days, emphasizing preference for settlement",
      event_data: {
        "trigger_cause" => "late_stage_negotiation",
        "urgency_level" => "critical",
        "trial_date" => 14.days.from_now.to_date
      },
      pressure_adjustment: {
        "plaintiff_min_increase" => -20000,
        "defendant_max_increase" => 50000
      },
      automatic: true
    )
  end

  # Scheduling methods
  def schedule_media_attention_event(round_number, delay_hours)
    trigger_time = Time.current + delay_hours.hours

    simulation.simulation_events.create!(
      event_type: :media_attention,
      trigger_round: round_number,
      triggered_at: trigger_time,
      impact_description: "Media outlet schedules investigative report on workplace harassment case",
      event_data: {
        "scheduled_event" => true,
        "media_type" => "investigative_journalism",
        "coverage_scope" => "local_business_community"
      },
      pressure_adjustment: {
        "plaintiff_min_increase" => 20000,
        "defendant_max_increase" => 45000
      },
      automatic: true
    )
  end

  def schedule_witness_change_event(round_number, delay_hours)
    trigger_time = Time.current + delay_hours.hours

    simulation.simulation_events.create!(
      event_type: :witness_change,
      trigger_round: round_number,
      triggered_at: trigger_time,
      impact_description: "Additional witness discovered through ongoing investigation",
      event_data: {
        "scheduled_event" => true,
        "discovery_method" => "investigation",
        "witness_type" => "corroborating_colleague"
      },
      pressure_adjustment: {
        "defendant_max_increase" => 65000
      },
      automatic: true
    )
  end

  def schedule_ipo_delay_event(round_number, delay_hours)
    trigger_time = Time.current + delay_hours.hours

    simulation.simulation_events.create!(
      event_type: :ipo_delay,
      trigger_round: round_number,
      triggered_at: trigger_time,
      impact_description: "Investment bank raises concerns about pending litigation impact on IPO timeline",
      event_data: {
        "scheduled_event" => true,
        "financial_impact" => "ipo_timeline_risk",
        "investor_concern" => "litigation_uncertainty"
      },
      pressure_adjustment: {
        "defendant_max_increase" => 80000
      },
      automatic: true
    )
  end

  def schedule_court_deadline_event(round_number, delay_hours)
    trigger_time = Time.current + delay_hours.hours

    simulation.simulation_events.create!(
      event_type: :court_deadline,
      trigger_round: round_number,
      triggered_at: trigger_time,
      impact_description: "Court administrator schedules case for trial calendar review",
      event_data: {
        "scheduled_event" => true,
        "court_action" => "trial_scheduling",
        "timeline_pressure" => "moderate"
      },
      pressure_adjustment: {
        "plaintiff_min_increase" => 10000,
        "defendant_max_increase" => 35000
      },
      automatic: true
    )
  end

  def apply_event_effects!(event)
    # Apply pressure adjustments
    event.apply_pressure_adjustments!

    # Mark event as applied
    event.event_data = event.event_data.merge("applied" => true, "applied_at" => Time.current.iso8601)
    event.save!

    # Trigger any cascade effects
    trigger_cascade_effects!(event)
  end

  def trigger_cascade_effects!(event)
    # Some events trigger follow-up events
    case event.event_type
    when "media_attention"
      # Media attention might trigger additional business pressure
      if rand < 0.3 # 30% chance
        schedule_business_pressure_cascade(event)
      end
    when "ipo_delay"
      # IPO delay might trigger board pressure
      if rand < 0.4 # 40% chance
        schedule_board_pressure_cascade(event)
      end
    end
  end

  def schedule_business_pressure_cascade(media_event)
    # Schedule follow-up business pressure event
    simulation.simulation_events.create!(
      event_type: :additional_evidence,
      trigger_round: media_event.trigger_round,
      triggered_at: 2.hours.from_now,
      impact_description: "Media coverage prompts company stakeholders to push for quick resolution",
      event_data: {
        "cascade_event" => true,
        "parent_event_id" => media_event.id,
        "cascade_type" => "media_business_pressure"
      },
      pressure_adjustment: {
        "defendant_max_increase" => 25000
      },
      automatic: true
    )
  end

  def schedule_board_pressure_cascade(ipo_event)
    # Schedule follow-up board pressure
    simulation.simulation_events.create!(
      event_type: :additional_evidence,
      trigger_round: ipo_event.trigger_round,
      triggered_at: 1.hour.from_now,
      impact_description: "Board of directors requests immediate resolution to protect business interests",
      event_data: {
        "cascade_event" => true,
        "parent_event_id" => ipo_event.id,
        "cascade_type" => "ipo_board_pressure"
      },
      pressure_adjustment: {
        "defendant_max_increase" => 40000
      },
      automatic: true
    )
  end

  def generate_event_notifications!(event)
    # Generate client feedback for affected teams
    feedback_service = ClientFeedbackService.new(simulation)

    affected_teams = [simulation.plaintiff_team, simulation.defendant_team].compact
    feedback_service.generate_event_feedback!(event, affected_teams)
  end

  # Trigger condition methods
  def should_schedule_media_event?
    !simulation.simulation_events.exists?(event_type: :media_attention) && rand < 0.6
  end

  def should_schedule_witness_event?
    !simulation.simulation_events.exists?(event_type: :witness_change) && rand < 0.5
  end

  def should_schedule_business_pressure_event?
    simulation.case.case_type == "sexual_harassment" && rand < 0.55
  end

  def should_schedule_court_deadline_event?
    simulation.current_round >= 4 && rand < 0.7
  end

  def should_trigger_media_attention_now?(round_number)
    return false if simulation.simulation_events.exists?(event_type: :media_attention)
    return false if round_number <= 1

    # Higher probability if settlement gap is large
    current_round = simulation.current_negotiation_round
    rand < if current_round&.settlement_gap && current_round.settlement_gap > 100000
      0.4
    else
      0.2
    end
  end

  def should_trigger_witness_change_now?(round_number)
    return false if simulation.simulation_events.exists?(event_type: :witness_change)
    return false if round_number <= 2

    # More likely if plaintiff offers are conservative
    recent_plaintiff_offers = SettlementOffer.joins(:negotiation_round)
      .joins(:team)
      .joins("JOIN case_teams ON teams.id = case_teams.team_id")
      .where(case_teams: {role: :plaintiff})
      .where(negotiation_rounds: {simulation: simulation})
      .where("negotiation_rounds.round_number >= ?", round_number - 1)

    if recent_plaintiff_offers.any?
      avg_offer = recent_plaintiff_offers.average(:amount)
      conservative_threshold = simulation.plaintiff_ideal * 0.8
      avg_offer < conservative_threshold && rand < 0.35
    else
      rand < 0.25
    end
  end

  def should_trigger_business_pressure_now?(round_number)
    return false if simulation.simulation_events.exists?(event_type: :ipo_delay)
    return false if round_number <= 3

    # More likely for sexual harassment cases and later rounds
    is_harassment_case = simulation.case.case_type == "sexual_harassment"
    base_probability = is_harassment_case ? 0.3 : 0.15

    rand < base_probability
  end
end
