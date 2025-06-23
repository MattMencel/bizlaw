# frozen_string_literal: true

module Api
  module V1
    # Simulation Status API controller for real-time simulation data
    class SimulationStatusController < BaseController
      before_action :set_case
      before_action :set_simulation
      before_action :verify_team_participation

      def show
        authorize @simulation, :show?

        render json: {
          simulation: simulation_status_data,
          current_round: current_round_data,
          team_status: team_status_data,
          client_mood: client_mood_data,
          pressure_indicators: pressure_indicators_data,
          recent_events: recent_events_data,
          negotiation_progress: negotiation_progress_data
        }
      end

      def client_mood
        authorize @simulation, :show?

        feedback_service = ClientFeedbackService.new(@simulation)
        mood_data = feedback_service.get_client_mood_indicator(current_user_team)

        render json: {
          client_mood: mood_data,
          feedback_summary: feedback_service.get_feedback_summary_for_team(current_user_team),
          strategic_guidance: get_strategic_guidance
        }
      end

      def pressure_status
        authorize @simulation, :show?

        dynamics_service = SimulationDynamicsService.new(@simulation)

        render json: {
          pressure_level: dynamics_service.current_pressure_level,
          pressure_sources: analyze_pressure_sources,
          acceptable_ranges: dynamics_service.current_acceptable_ranges,
          recent_adjustments: get_recent_range_adjustments,
          market_conditions: get_market_conditions
        }
      end

      def negotiation_history
        authorize @simulation, :show?

        render json: {
          rounds: negotiation_rounds_summary,
          settlement_progression: settlement_progression_data,
          argument_quality_trends: argument_quality_trends,
          gap_analysis: gap_analysis_data,
          timeline: negotiation_timeline_data
        }
      end

      def events_feed
        authorize @simulation, :show?

        events = @simulation.simulation_events
          .triggered
          .order(triggered_at: :desc)
          .limit(20)

        render json: {
          events: events.map { |event| format_event_data(event) },
          upcoming_events: get_upcoming_events,
          event_impact_summary: get_event_impact_summary
        }
      end

      private

      def set_case
        @case = Case.find(params[:case_id])
      rescue ActiveRecord::RecordNotFound
        render json: {error: "Case not found"}, status: :not_found
      end

      def set_simulation
        @simulation = @case.active_simulation

        unless @simulation
          api_error(
            message: "This case does not have an active simulation",
            status: :not_found
          )
        end
      end

      def verify_team_participation
        unless current_user_team
          api_error(
            message: "You are not assigned to a team for this case",
            status: :forbidden
          )
        end
      end

      def current_user_team
        @current_user_team ||= current_user.teams
          .joins(:case_teams)
          .where(case_teams: {case: @case})
          .first
      end

      def simulation_status_data
        {
          id: @simulation.id,
          status: @simulation.status,
          current_round: @simulation.current_round,
          total_rounds: @simulation.total_rounds,
          start_date: @simulation.start_date,
          end_date: @simulation.end_date,
          auto_events_enabled: @simulation.auto_events_enabled,
          pressure_escalation_rate: @simulation.pressure_escalation_rate
        }
      end

      def current_round_data
        current_round = @simulation.current_negotiation_round
        return nil unless current_round

        {
          id: current_round.id,
          round_number: current_round.round_number,
          status: current_round.status,
          deadline: current_round.deadline,
          time_remaining: current_round.time_remaining,
          started_at: current_round.started_at,
          both_submitted: current_round.both_teams_submitted?,
          settlement_reached: current_round.settlement_reached?,
          settlement_gap: current_round.settlement_gap
        }
      end

      def team_status_data
        case_team = current_user_team.case_teams.find_by(case: @case)
        team_role = case_team&.role

        current_round = @simulation.current_negotiation_round
        team_offer = nil

        if current_round && team_role
          team_offer = if team_role == "plaintiff"
            current_round.plaintiff_offer
          else
            current_round.defendant_offer
          end
        end

        {
          team_id: current_user_team.id,
          team_name: current_user_team.name,
          role: team_role,
          has_submitted_current_round: team_offer.present?,
          current_offer: team_offer ? format_settlement_offer(team_offer) : nil,
          can_submit: current_round&.active? && Time.current <= current_round&.deadline
        }
      end

      def client_mood_data
        feedback_service = ClientFeedbackService.new(@simulation)
        feedback_service.get_client_mood_indicator(current_user_team)
      end

      def pressure_indicators_data
        dynamics_service = SimulationDynamicsService.new(@simulation)

        {
          overall_pressure: dynamics_service.current_pressure_level,
          pressure_description: describe_pressure_level(dynamics_service.current_pressure_level),
          contributing_factors: analyze_pressure_sources,
          trend: calculate_pressure_trend
        }
      end

      def recent_events_data
        @simulation.simulation_events
          .triggered
          .where("triggered_at >= ?", 24.hours.ago)
          .order(triggered_at: :desc)
          .limit(5)
          .map { |event| format_event_data(event) }
      end

      def negotiation_progress_data
        completed_rounds = @simulation.negotiation_rounds.completed.count
        total_rounds = @simulation.total_rounds

        {
          rounds_completed: completed_rounds,
          total_rounds: total_rounds,
          progress_percentage: (completed_rounds.to_f / total_rounds * 100).round(1),
          estimated_completion: estimate_completion_date,
          pace: calculate_negotiation_pace
        }
      end

      def format_settlement_offer(offer)
        {
          id: offer.id,
          amount: offer.amount,
          justification: offer.justification,
          non_monetary_terms: offer.non_monetary_terms,
          submitted_at: offer.submitted_at,
          quality_score: offer.quality_score
        }
      end

      def format_event_data(event)
        {
          id: event.id,
          event_type: event.event_type,
          description: event.impact_description,
          triggered_at: event.triggered_at,
          trigger_round: event.trigger_round,
          notification_message: event.notification_message,
          pressure_impact: event.pressure_impact_summary
        }
      end

      def get_strategic_guidance
        dynamics_service = SimulationDynamicsService.new(@simulation)

        dynamics_service.generate_round_feedback(
          @simulation.current_round,
          current_user_team
        )
      end

      def analyze_pressure_sources
        sources = []

        # Time pressure
        round_progress = @simulation.current_round.to_f / @simulation.total_rounds
        if round_progress > 0.7
          sources << {
            type: "time_pressure",
            description: "Late stage negotiation increasing settlement urgency",
            impact: "high"
          }
        end

        # Event pressure
        recent_events = @simulation.simulation_events
          .triggered
          .where("triggered_at >= ?", 48.hours.ago)

        if recent_events.any?
          sources << {
            type: "external_events",
            description: "Recent developments affecting case dynamics",
            impact: "moderate",
            events_count: recent_events.count
          }
        end

        # Settlement gap pressure
        current_round = @simulation.current_negotiation_round
        if current_round&.both_teams_submitted? && current_round.settlement_gap
          gap_size = current_round.settlement_gap
          if gap_size > 100000
            sources << {
              type: "settlement_gap",
              description: "Large gap between positions requiring resolution",
              impact: "high"
            }
          end
        end

        sources
      end

      def get_recent_range_adjustments
        # Look for recent simulation events that included range adjustments
        @simulation.simulation_events
          .where("triggered_at >= ?", 24.hours.ago)
          .where.not(pressure_adjustment: {})
          .order(triggered_at: :desc)
          .limit(3)
          .map do |event|
          {
            event_type: event.event_type,
            triggered_at: event.triggered_at,
            adjustments: event.pressure_adjustment,
            description: event.impact_description
          }
        end
      end

      def get_market_conditions
        # Abstract representation of current negotiation climate
        pressure_level = SimulationDynamicsService.new(@simulation).current_pressure_level

        {
          climate: describe_negotiation_climate(pressure_level),
          settlement_likelihood: calculate_settlement_likelihood,
          recommended_strategy: get_strategy_recommendation
        }
      end

      def negotiation_rounds_summary
        @simulation.negotiation_rounds
          .completed
          .includes(:settlement_offers)
          .order(:round_number)
          .map do |round|
          {
            round_number: round.round_number,
            completed_at: round.completed_at,
            plaintiff_amount: round.plaintiff_offer&.amount,
            defendant_amount: round.defendant_offer&.amount,
            settlement_gap: round.settlement_gap,
            settlement_reached: round.settlement_reached?
          }
        end
      end

      def settlement_progression_data
        rounds = negotiation_rounds_summary
        return {} if rounds.empty?

        {
          plaintiff_offers: rounds.map { |r| {round: r[:round_number], amount: r[:plaintiff_amount]} }.compact,
          defendant_offers: rounds.map { |r| {round: r[:round_number], amount: r[:defendant_amount]} }.compact,
          gap_trend: rounds.map { |r| {round: r[:round_number], gap: r[:settlement_gap]} }.compact,
          convergence_rate: calculate_convergence_rate(rounds)
        }
      end

      def argument_quality_trends
        offers = SettlementOffer.joins(:negotiation_round)
          .where(negotiation_rounds: {simulation: @simulation})
          .where(team: current_user_team)
          .order("negotiation_rounds.round_number")

        offers.map do |offer|
          {
            round: offer.round_number,
            quality_score: offer.quality_score,
            assessment: offer.quality_assessment
          }
        end
      end

      def gap_analysis_data
        current_round = @simulation.current_negotiation_round
        return {} unless current_round&.both_teams_submitted?

        {
          current_gap: current_round.settlement_gap,
          gap_as_percentage: calculate_gap_percentage(current_round),
          closing_rate: calculate_gap_closing_rate,
          projected_settlement_round: project_settlement_round
        }
      end

      def negotiation_timeline_data
        events = []

        # Add round completions
        @simulation.negotiation_rounds.completed.each do |round|
          events << {
            type: "round_completed",
            timestamp: round.completed_at,
            description: "Round #{round.round_number} completed",
            data: {round_number: round.round_number}
          }
        end

        # Add simulation events
        @simulation.simulation_events.triggered.each do |event|
          events << {
            type: "simulation_event",
            timestamp: event.triggered_at,
            description: event.impact_description,
            data: {event_type: event.event_type}
          }
        end

        events.sort_by { |e| e[:timestamp] }.last(20).reverse
      end

      def get_upcoming_events
        @simulation.simulation_events
          .pending
          .order(:triggered_at)
          .limit(5)
          .map { |event| format_event_data(event) }
      end

      def get_event_impact_summary
        triggered_events = @simulation.simulation_events.triggered

        {
          total_events: triggered_events.count,
          pressure_increase: calculate_total_pressure_increase(triggered_events),
          range_adjustments: calculate_total_range_adjustments(triggered_events)
        }
      end

      # Helper methods
      def describe_pressure_level(level)
        case level
        when 0.0..0.3 then "Low pressure - relaxed negotiation environment"
        when 0.3..0.6 then "Moderate pressure - some urgency building"
        when 0.6..0.8 then "High pressure - significant settlement incentives"
        when 0.8..1.0 then "Critical pressure - urgent resolution needed"
        else "Unknown pressure level"
        end
      end

      def calculate_pressure_trend
        # Compare current pressure to pressure from previous round
        # This would need historical pressure tracking to be fully implemented
        "stable" # Simplified for now
      end

      def estimate_completion_date
        return nil if @simulation.completed?

        remaining_rounds = @simulation.total_rounds - @simulation.current_round + 1
        hours_per_round = @simulation.simulation_config.dig("hours_per_round") || 48

        Time.current + (remaining_rounds * hours_per_round).hours
      end

      def calculate_negotiation_pace
        elapsed_time = Time.current - @simulation.start_date
        completed_rounds = @simulation.current_round - 1

        return "unknown" if completed_rounds.zero?

        hours_per_round = elapsed_time / completed_rounds / 1.hour

        case hours_per_round
        when 0..24 then "fast"
        when 24..48 then "normal"
        when 48..72 then "slow"
        else "very_slow"
        end
      end

      def describe_negotiation_climate(pressure_level)
        case pressure_level
        when 0.0..0.4 then "Collaborative"
        when 0.4..0.7 then "Competitive"
        when 0.7..1.0 then "Urgent"
        else "Unknown"
        end
      end

      def calculate_settlement_likelihood
        current_round = @simulation.current_negotiation_round
        return "unknown" unless current_round&.both_teams_submitted?

        gap = current_round.settlement_gap
        return "high" if gap && gap < 50000
        return "moderate" if gap && gap < 150000
        return "low" if gap && gap > 300000

        "moderate"
      end

      def get_strategy_recommendation
        pressure_level = SimulationDynamicsService.new(@simulation).current_pressure_level
        round_number = @simulation.current_round

        if round_number <= 2
          "Focus on establishing strong legal foundation"
        elsif round_number <= 4
          "Consider creative non-monetary terms"
        elsif pressure_level > 0.7
          "Time pressure mounting - focus on core settlement terms"
        else
          "Maintain strategic flexibility while showing good faith"
        end
      end

      def calculate_convergence_rate(rounds)
        return 0 if rounds.length < 2

        gaps = rounds.pluck(:settlement_gap).compact
        return 0 if gaps.length < 2

        initial_gap = gaps.first
        latest_gap = gaps.last

        return 0 if initial_gap.zero?

        ((initial_gap - latest_gap) / initial_gap.to_f * 100).round(1)
      end

      def calculate_gap_percentage(round)
        return 0 unless round.settlement_gap

        plaintiff_amount = round.plaintiff_offer&.amount || 0
        defendant_amount = round.defendant_offer&.amount || 0
        average = (plaintiff_amount + defendant_amount) / 2.0

        return 0 if average.zero?

        (round.settlement_gap / average * 100).round(1)
      end

      def calculate_gap_closing_rate
        rounds = negotiation_rounds_summary
        gaps = rounds.pluck(:settlement_gap).compact

        return 0 if gaps.length < 2

        # Calculate average reduction per round
        total_reduction = gaps.first - gaps.last
        rounds_elapsed = gaps.length - 1

        return 0 if rounds_elapsed.zero?

        (total_reduction / rounds_elapsed).round
      end

      def project_settlement_round
        closing_rate = calculate_gap_closing_rate
        current_gap = @simulation.current_negotiation_round&.settlement_gap

        return nil unless closing_rate > 0 && current_gap

        rounds_needed = (current_gap / closing_rate).ceil
        projected_round = @simulation.current_round + rounds_needed

        (projected_round <= @simulation.total_rounds) ? projected_round : nil
      end

      def calculate_total_pressure_increase(events)
        events.sum do |event|
          adjustments = event.pressure_adjustment || {}
          plaintiff_increase = adjustments["plaintiff_min_increase"]&.to_f || 0
          defendant_increase = adjustments["defendant_max_increase"]&.to_f || 0
          plaintiff_increase + defendant_increase
        end
      end

      def calculate_total_range_adjustments(events)
        {
          plaintiff_adjustments: events.sum { |e| e.pressure_adjustment["plaintiff_min_increase"]&.to_f || 0 },
          defendant_adjustments: events.sum { |e| e.pressure_adjustment["defendant_max_increase"]&.to_f || 0 }
        }
      end
    end
  end
end
