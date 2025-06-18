# frozen_string_literal: true

class SimulationOrchestrationService
  attr_reader :simulation

  def initialize(simulation)
    @simulation = simulation
  end

  # Main orchestration method called when a settlement offer is submitted
  def process_settlement_offer!(settlement_offer)
    results = {
      feedbacks_generated: [],
      events_triggered: [],
      range_adjustments: {},
      round_advancement: nil,
      notifications: []
    }

    # 1. Generate client feedback
    feedback_service = ClientFeedbackService.new(simulation)
    feedbacks = feedback_service.generate_feedback_for_offer!(settlement_offer)
    results[:feedbacks_generated] = feedbacks

    # 2. Trigger simulation events if appropriate
    event_orchestrator = SimulationEventOrchestrator.new(simulation)
    events = event_orchestrator.orchestrate_round_events!(simulation.current_round)
    results[:events_triggered] = events

    # 3. Apply dynamic range adjustments
    dynamics_service = SimulationDynamicsService.new(simulation)
    adjustments = dynamics_service.adjust_ranges_for_round!(simulation.current_round)
    results[:range_adjustments] = adjustments

    # 4. Check for round advancement or simulation completion
    advancement = check_and_process_advancement!(settlement_offer)
    results[:round_advancement] = advancement

    # 5. Generate notifications for all participants
    notifications = generate_participant_notifications(settlement_offer, results)
    results[:notifications] = notifications

    results
  end

  # Process round completion and potential simulation advancement
  def process_round_completion!(negotiation_round)
    results = {
      round_completed: true,
      settlement_reached: false,
      arbitration_triggered: false,
      simulation_completed: false,
      next_round_created: false,
      feedbacks_generated: [],
      events_scheduled: []
    }

    # Mark round as completed
    negotiation_round.complete!

    # Check for settlement
    if negotiation_round.settlement_reached?
      results[:settlement_reached] = true
      results[:simulation_completed] = true
      simulation.complete!

      # Generate settlement satisfaction feedback
      feedback_service = ClientFeedbackService.new(simulation)
      feedbacks = feedback_service.generate_settlement_feedback!(negotiation_round)
      results[:feedbacks_generated] = feedbacks

    elsif simulation.current_round >= simulation.total_rounds
      # Trigger arbitration
      results[:arbitration_triggered] = true
      simulation.trigger_arbitration!

      # Generate arbitration feedback
      feedback_service = ClientFeedbackService.new(simulation)
      feedbacks = feedback_service.generate_arbitration_feedback!
      results[:feedbacks_generated] = feedbacks

      # Calculate arbitration outcome
      ArbitrationOutcome.calculate_outcome!(simulation)

    else
      # Advance to next round
      if simulation.can_advance_round?
        simulation.next_round!
        results[:next_round_created] = true

        # Generate round transition feedback
        feedback_service = ClientFeedbackService.new(simulation)
        feedbacks = feedback_service.generate_round_transition_feedback!(
          simulation.current_round - 1,
          simulation.current_round
        )
        results[:feedbacks_generated] = feedbacks

        # Schedule events for the new round
        event_orchestrator = SimulationEventOrchestrator.new(simulation)
        events = event_orchestrator.schedule_future_events!(simulation.current_round)
        results[:events_scheduled] = events
      end
    end

    results
  end

  # Process simulation events and their effects
  def process_simulation_event!(event)
    results = {
      event_applied: false,
      pressure_adjustments: {},
      feedbacks_generated: [],
      cascade_events: []
    }

    # Apply event effects
    if event.apply_pressure_adjustments!
      results[:event_applied] = true
      results[:pressure_adjustments] = event.pressure_adjustment
    end

    # Generate event-specific feedback
    feedback_service = ClientFeedbackService.new(simulation)
    affected_teams = [ simulation.plaintiff_team, simulation.defendant_team ].compact
    feedbacks = feedback_service.generate_event_feedback!(event, affected_teams)
    results[:feedbacks_generated] = feedbacks

    # Check for cascade events
    event_orchestrator = SimulationEventOrchestrator.new(simulation)
    # This would need to be implemented in the orchestrator
    # cascade_events = event_orchestrator.check_cascade_effects!(event)
    # results[:cascade_events] = cascade_events

    results
  end

  # Get comprehensive simulation status for API endpoints
  def get_comprehensive_status(user)
    user_team = get_user_team(user)
    dynamics_service = SimulationDynamicsService.new(simulation)
    feedback_service = ClientFeedbackService.new(simulation)

    {
      simulation: {
        id: simulation.id,
        status: simulation.status,
        current_round: simulation.current_round,
        total_rounds: simulation.total_rounds,
        pressure_level: dynamics_service.current_pressure_level,
        acceptable_ranges: dynamics_service.current_acceptable_ranges
      },
      current_round: get_current_round_status,
      team_status: get_team_status(user_team),
      client_mood: user_team ? feedback_service.get_client_mood_indicator(user_team) : nil,
      recent_events: get_recent_events_summary,
      negotiation_progress: get_negotiation_progress_summary
    }
  end

  # Validate that a simulation is ready to start
  def validate_simulation_readiness
    errors = []

    # Check basic configuration
    errors << "Plaintiff minimum acceptable amount must be set" unless simulation.plaintiff_min_acceptable&.positive?
    errors << "Defendant maximum acceptable amount must be set" unless simulation.defendant_max_acceptable&.positive?
    errors << "Both plaintiff and defendant teams must be assigned" unless simulation.plaintiff_team && simulation.defendant_team

    # Check logical consistency
    if simulation.plaintiff_min_acceptable && simulation.plaintiff_ideal &&
       simulation.plaintiff_min_acceptable > simulation.plaintiff_ideal
      errors << "Plaintiff minimum cannot exceed ideal amount"
    end

    if simulation.defendant_ideal && simulation.defendant_max_acceptable &&
       simulation.defendant_ideal > simulation.defendant_max_acceptable
      errors << "Defendant ideal cannot exceed maximum amount"
    end

    # Check for settlement possibility
    if simulation.plaintiff_min_accessible && simulation.defendant_max_acceptable &&
       simulation.plaintiff_min_accessible > simulation.defendant_max_acceptable
      errors << "Warning: Current ranges make settlement impossible - consider adjustment"
    end

    errors
  end

  # Start a simulation
  def start_simulation!
    errors = validate_simulation_readiness
    raise StandardError, "Simulation validation failed: #{errors.join(', ')}" if errors.any?

    simulation.update!(status: :active, start_date: Time.current)

    # Create initial round
    initial_round = simulation.negotiation_rounds.create!(
      round_number: 1,
      deadline: Time.current + 48.hours, # Default 48 hours
      status: :active
    )

    # Schedule initial events
    event_orchestrator = SimulationEventOrchestrator.new(simulation)
    event_orchestrator.schedule_future_events!(2, 24) # Schedule round 2 events 24 hours ahead

    {
      simulation_started: true,
      initial_round: initial_round,
      start_time: simulation.start_date
    }
  end

  private

  def check_and_process_advancement!(settlement_offer)
    negotiation_round = settlement_offer.negotiation_round
    return nil unless negotiation_round.both_teams_submitted?

    if negotiation_round.settlement_reached?
      process_round_completion!(negotiation_round)
    elsif negotiation_round.can_complete?
      # Auto-advance if configured
      if simulation.simulation_config.dig("auto_advance_rounds")
        process_round_completion!(negotiation_round)
      else
        { awaiting_instructor_advance: true }
      end
    end
  end

  def generate_participant_notifications(settlement_offer, processing_results)
    notifications = []

    # Notify about new feedbacks
    processing_results[:feedbacks_generated].each do |feedback|
      notifications << {
        type: "client_feedback",
        team_id: feedback.team_id,
        message: feedback.formatted_message,
        timestamp: feedback.created_at
      }
    end

    # Notify about events
    processing_results[:events_triggered].each do |event|
      notifications << {
        type: "simulation_event",
        message: event.notification_message,
        timestamp: event.triggered_at,
        affects_all_teams: true
      }
    end

    # Notify about range adjustments
    if processing_results[:range_adjustments].any?
      notifications << {
        type: "range_adjustment",
        message: "Settlement ranges have been adjusted based on simulation dynamics",
        timestamp: Time.current,
        affects_all_teams: true
      }
    end

    notifications
  end

  def get_user_team(user)
    user.teams.joins(:case_teams).where(case_teams: { case: simulation.case }).first
  end

  def get_current_round_status
    current_round = simulation.current_negotiation_round
    return nil unless current_round

    {
      id: current_round.id,
      round_number: current_round.round_number,
      status: current_round.status,
      deadline: current_round.deadline,
      time_remaining: current_round.time_remaining,
      both_submitted: current_round.both_teams_submitted?,
      settlement_reached: current_round.settlement_reached?
    }
  end

  def get_team_status(team)
    return nil unless team

    case_team = team.case_teams.find_by(case: simulation.case)
    current_round = simulation.current_negotiation_round

    team_offer = nil
    if current_round && case_team
      team_offer = if case_team.role == "plaintiff"
                     current_round.plaintiff_offer
      else
                     current_round.defendant_offer
      end
    end

    {
      team_id: team.id,
      role: case_team&.role,
      has_submitted: team_offer.present?,
      can_submit: current_round&.active? && Time.current <= current_round&.deadline
    }
  end

  def get_recent_events_summary
    simulation.simulation_events
              .triggered
              .where("triggered_at >= ?", 24.hours.ago)
              .order(triggered_at: :desc)
              .limit(5)
              .map do |event|
      {
        event_type: event.event_type,
        description: event.impact_description,
        triggered_at: event.triggered_at
      }
    end
  end

  def get_negotiation_progress_summary
    completed_rounds = simulation.negotiation_rounds.completed.count

    {
      rounds_completed: completed_rounds,
      total_rounds: simulation.total_rounds,
      progress_percentage: (completed_rounds.to_f / simulation.total_rounds * 100).round(1)
    }
  end
end
