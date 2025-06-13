# frozen_string_literal: true

class SimulationDynamicsService
  attr_reader :simulation

  def initialize(simulation)
    @simulation = simulation
  end

  # Main method to calculate and apply dynamic range adjustments
  def adjust_ranges_for_round!(round_number)
    return false unless simulation.active?
    return false if round_number <= 1 # No adjustments for first round

    adjustments = calculate_range_adjustments(round_number)
    apply_adjustments!(adjustments) if adjustments.any?
  end

  # Calculate pressure-based range adjustments
  def calculate_range_adjustments(round_number)
    adjustments = {}

    # Time-based pressure (ranges become more flexible over time)
    time_adjustments = calculate_time_pressure_adjustments(round_number)
    adjustments.merge!(time_adjustments)

    # Event-based pressure adjustments
    event_adjustments = calculate_event_pressure_adjustments(round_number)
    adjustments.merge!(event_adjustments)

    # Argument quality impact
    quality_adjustments = calculate_argument_quality_adjustments(round_number)
    adjustments.merge!(quality_adjustments)

    # Media pressure escalation
    media_adjustments = calculate_media_pressure_adjustments(round_number)
    adjustments.merge!(media_adjustments)

    adjustments
  end

  # Check if automatic events should be triggered for this round
  def trigger_events_for_round!(round_number)
    return false unless simulation.should_trigger_events?

    events_triggered = []

    # Round-specific event triggers
    case round_number
    when 2
      if should_trigger_media_attention?
        event = SimulationEvent.create_media_attention_event(simulation, round_number)
        events_triggered << event
      end
    when 3
      if should_trigger_witness_change?
        event = SimulationEvent.create_witness_change_event(simulation, round_number)
        events_triggered << event
      end
    when 4
      if should_trigger_ipo_delay?
        event = SimulationEvent.create_ipo_delay_event(simulation, round_number)
        events_triggered << event
      end
    when 5
      if should_trigger_court_deadline?
        event = SimulationEvent.create_court_deadline_event(simulation, round_number)
        events_triggered << event
      end
    end

    # Apply pressure adjustments from triggered events
    events_triggered.each(&:apply_pressure_adjustments!)

    events_triggered
  end

  # Generate contextual feedback based on current simulation state
  def generate_round_feedback(round_number, team, settlement_offer = nil)
    feedback_components = []

    # Settlement offer specific feedback
    if settlement_offer
      offer_feedback = generate_offer_feedback(settlement_offer, team)
      feedback_components << offer_feedback
    end

    # Round-specific strategic guidance
    strategic_feedback = generate_strategic_feedback(round_number, team)
    feedback_components << strategic_feedback

    # Pressure situation feedback
    pressure_feedback = generate_pressure_feedback(round_number, team)
    feedback_components << pressure_feedback if pressure_feedback

    feedback_components.compact.join("\n\n")
  end

  # Calculate current pressure level affecting the case
  def current_pressure_level
    base_pressure = calculate_base_pressure
    time_pressure = calculate_time_pressure_factor
    event_pressure = calculate_event_pressure_factor
    media_pressure = calculate_media_pressure_factor

    total_pressure = (base_pressure + time_pressure + event_pressure + media_pressure) / 4.0
    total_pressure.clamp(0.0, 1.0)
  end

  # Get current acceptable ranges (including any dynamic adjustments)
  def current_acceptable_ranges
    {
      plaintiff: {
        minimum: simulation.plaintiff_min_acceptable,
        ideal: simulation.plaintiff_ideal
      },
      defendant: {
        ideal: simulation.defendant_ideal,
        maximum: simulation.defendant_max_acceptable
      },
      pressure_level: current_pressure_level,
      overlap_zone: calculate_overlap_zone
    }
  end

  private

  def calculate_time_pressure_adjustments(round_number)
    adjustments = {}
    pressure_rate = simulation.pressure_escalation_rate
    
    # Base adjustment percentage per round based on escalation rate
    base_adjustment = case pressure_rate
                     when "low" then 0.02      # 2% per round
                     when "moderate" then 0.035 # 3.5% per round  
                     when "high" then 0.05     # 5% per round
                     else 0.035
                     end

    # Progressive increase based on round number
    round_multiplier = round_number - 1
    adjustment_percentage = base_adjustment * round_multiplier

    # Apply adjustments (ranges become more flexible under pressure)
    plaintiff_increase = simulation.plaintiff_min_acceptable * adjustment_percentage * 0.5
    defendant_increase = simulation.defendant_max_acceptable * adjustment_percentage

    adjustments[:plaintiff_min_decrease] = -plaintiff_increase if plaintiff_increase > 0
    adjustments[:defendant_max_increase] = defendant_increase if defendant_increase > 0

    adjustments
  end

  def calculate_event_pressure_adjustments(round_number)
    # This is handled by individual SimulationEvent instances
    # We just aggregate their cumulative effect here
    recent_events = simulation.simulation_events
                             .where("trigger_round <= ?", round_number)
                             .where("triggered_at <= ?", Time.current)

    total_plaintiff_adjustment = recent_events.sum do |event|
      event.pressure_adjustment["plaintiff_min_increase"]&.to_f || 0
    end

    total_defendant_adjustment = recent_events.sum do |event|
      event.pressure_adjustment["defendant_max_increase"]&.to_f || 0
    end

    {
      event_plaintiff_min_increase: total_plaintiff_adjustment,
      event_defendant_max_increase: total_defendant_adjustment
    }
  end

  def calculate_argument_quality_adjustments(round_number)
    adjustments = {}
    
    # Get completed rounds up to current point
    completed_rounds = simulation.negotiation_rounds
                                .where("round_number < ?", round_number)
                                .where(status: :completed)

    return adjustments if completed_rounds.empty?

    # Calculate average argument quality from settlement offers
    total_quality = 0
    offer_count = 0

    completed_rounds.each do |round|
      [round.plaintiff_offer, round.defendant_offer].compact.each do |offer|
        total_quality += offer.quality_score || 50
        offer_count += 1
      end
    end

    return adjustments if offer_count.zero?

    avg_quality = total_quality / offer_count.to_f

    # High quality arguments (>80) lead to more reasonable positions
    # Low quality arguments (<40) lead to more rigid positions
    if avg_quality > 80
      flexibility_bonus = simulation.plaintiff_min_acceptable * 0.03
      adjustments[:high_quality_plaintiff_flexibility] = -flexibility_bonus
      adjustments[:high_quality_defendant_flexibility] = simulation.defendant_max_acceptable * 0.03
    elsif avg_quality < 40
      rigidity_penalty = simulation.plaintiff_min_acceptable * 0.02
      adjustments[:low_quality_plaintiff_rigidity] = rigidity_penalty
      adjustments[:low_quality_defendant_rigidity] = -simulation.defendant_max_acceptable * 0.02
    end

    adjustments
  end

  def calculate_media_pressure_adjustments(round_number)
    media_events = simulation.simulation_events
                            .where(event_type: :media_attention)
                            .where("trigger_round <= ?", round_number)

    return {} if media_events.empty?

    # Media pressure increases settlement willingness for both sides
    media_count = media_events.count
    base_media_pressure = simulation.plaintiff_min_acceptable * 0.025 * media_count

    {
      media_plaintiff_flexibility: -base_media_pressure * 0.7,
      media_defendant_pressure: simulation.defendant_max_acceptable * 0.04 * media_count
    }
  end

  def apply_adjustments!(adjustments)
    plaintiff_total_change = 0
    defendant_total_change = 0

    # Sum all plaintiff minimum adjustments
    adjustments.each do |key, value|
      if key.to_s.include?("plaintiff") && key.to_s.include?("min")
        plaintiff_total_change += value
      elsif key.to_s.include?("defendant") && key.to_s.include?("max")
        defendant_total_change += value
      end
    end

    # Apply changes if significant enough (> $1000 change)
    if plaintiff_total_change.abs > 1000
      new_min = simulation.plaintiff_min_acceptable + plaintiff_total_change
      # Ensure it doesn't go below 0 or above ideal
      new_min = new_min.clamp(0, simulation.plaintiff_ideal)
      simulation.update!(plaintiff_min_acceptable: new_min)
    end

    if defendant_total_change.abs > 1000
      new_max = simulation.defendant_max_acceptable + defendant_total_change
      # Ensure it doesn't go below ideal
      new_max = [new_max, simulation.defendant_ideal].max
      simulation.update!(defendant_max_acceptable: new_max)
    end

    # Log the adjustments for audit trail
    simulation.simulation_events.create!(
      event_type: :additional_evidence, # Use existing enum value
      trigger_round: simulation.current_round,
      triggered_at: Time.current,
      impact_description: "Dynamic range adjustments applied based on simulation progress",
      event_data: {
        "adjustment_type" => "dynamic_range_calculation",
        "adjustments_applied" => adjustments,
        "plaintiff_change" => plaintiff_total_change,
        "defendant_change" => defendant_total_change
      },
      pressure_adjustment: {},
      automatic: true
    )
  end

  # Event triggering logic
  def should_trigger_media_attention?
    # Trigger media attention based on case progression and randomness
    base_probability = 0.6
    case_high_profile = simulation.case.case_type == "sexual_harassment"
    probability = case_high_profile ? base_probability + 0.2 : base_probability
    
    rand < probability
  end

  def should_trigger_witness_change?
    # More likely if negotiation gap is still large
    current_round = simulation.current_negotiation_round
    if current_round&.both_teams_submitted? && current_round.settlement_gap
      gap_threshold = simulation.plaintiff_ideal * 0.3
      large_gap = current_round.settlement_gap > gap_threshold
      rand < (large_gap ? 0.7 : 0.4)
    else
      rand < 0.5
    end
  end

  def should_trigger_ipo_delay?
    # More likely for corporate defendants in later rounds
    rand < 0.55
  end

  def should_trigger_court_deadline?
    # High probability in later rounds to create urgency
    rand < 0.8
  end

  # Feedback generation methods
  def generate_offer_feedback(settlement_offer, team)
    case_team = team.case_teams.find_by(case: simulation.case)
    role = case_team&.role
    
    return "Unable to provide feedback on this offer." unless role

    if role == "plaintiff"
      generate_plaintiff_offer_feedback(settlement_offer)
    else
      generate_defendant_offer_feedback(settlement_offer)
    end
  end

  def generate_plaintiff_offer_feedback(offer)
    amount = offer.amount
    min_acceptable = simulation.plaintiff_min_acceptable
    ideal = simulation.plaintiff_ideal

    if amount >= ideal * 0.95
      "Excellent opening position! This demand is strong and sets up favorable negotiations."
    elsif amount >= min_acceptable * 1.3
      "Solid demand that leaves good room for negotiation while showing seriousness."
    elsif amount >= min_acceptable
      "Reasonable position, though you may want to justify this amount carefully."
    else
      "This demand may be too conservative. Consider the full extent of damages suffered."
    end
  end

  def generate_defendant_offer_feedback(offer)
    amount = offer.amount
    max_acceptable = simulation.defendant_max_acceptable
    ideal = simulation.defendant_ideal

    if amount <= ideal * 1.1
      "Very reasonable offer that shows good faith and willingness to resolve."
    elsif amount <= max_acceptable * 0.8
      "Measured approach that positions well for continued negotiations."
    elsif amount <= max_acceptable
      "Acceptable range, though plaintiff may push for more."
    else
      "This offer may create negotiation difficulties. Consider more conservative positioning."
    end
  end

  def generate_strategic_feedback(round_number, team)
    case round_number
    when 1..2
      "Early rounds focus on establishing positions. Emphasize legal strength and clear damage calculations."
    when 3..4
      "Mid-negotiation requires strategic movement. Consider creative non-monetary terms to bridge gaps."
    when 5..6
      "Final rounds demand careful positioning. Settlement pressure is mounting for both sides."
    else
      "Focus on reasonable movement toward resolution."
    end
  end

  def generate_pressure_feedback(round_number, team)
    pressure = current_pressure_level
    
    if pressure > 0.7
      "High pressure situation. External factors are strongly encouraging settlement."
    elsif pressure > 0.4
      "Moderate pressure building. Consider how external factors affect your position."
    else
      nil # No pressure feedback needed
    end
  end

  # Pressure calculation methods
  def calculate_base_pressure
    case simulation.pressure_escalation_rate
    when "low" then 0.2
    when "moderate" then 0.3
    when "high" then 0.4
    else 0.3
    end
  end

  def calculate_time_pressure_factor
    round_progress = simulation.current_round.to_f / simulation.total_rounds
    round_progress * 0.4 # Max 40% pressure from time
  end

  def calculate_event_pressure_factor
    event_count = simulation.simulation_events.triggered.count
    [event_count * 0.15, 0.3].min # Max 30% pressure from events
  end

  def calculate_media_pressure_factor
    media_events = simulation.simulation_events.where(event_type: :media_attention).triggered.count
    [media_events * 0.2, 0.25].min # Max 25% pressure from media
  end

  def calculate_overlap_zone
    return nil if simulation.plaintiff_min_acceptable > simulation.defendant_max_acceptable

    {
      min: simulation.plaintiff_min_acceptable,
      max: simulation.defendant_max_acceptable,
      size: simulation.defendant_max_acceptable - simulation.plaintiff_min_acceptable
    }
  end
end