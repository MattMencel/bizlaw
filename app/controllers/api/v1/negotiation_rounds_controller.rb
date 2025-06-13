# frozen_string_literal: true

module Api
  module V1
    # Negotiation Rounds API controller for simulation management
    class NegotiationRoundsController < BaseController
      before_action :set_case
      before_action :set_simulation
      before_action :set_negotiation_round, only: %i[show update]
      before_action :verify_team_participation, only: %i[create update]

      def index
        authorize @simulation, :show?
        
        @rounds = @simulation.negotiation_rounds
                            .includes(:settlement_offers)
                            .by_round_number

        render json: NegotiationRoundSerializer.new(
          @rounds,
          include: %i[settlement_offers],
          params: { current_user: current_user }
        ).serializable_hash
      end

      def show
        authorize @simulation, :show?
        
        render json: NegotiationRoundSerializer.new(
          @negotiation_round,
          include: %i[settlement_offers],
          params: { current_user: current_user }
        ).serializable_hash
      end

      def create
        authorize @simulation, :participate?

        @negotiation_round = find_or_create_current_round
        
        # Create settlement offer for the team
        @settlement_offer = build_settlement_offer

        if @settlement_offer.save
          # Trigger simulation dynamics
          handle_offer_submission
          
          render json: SettlementOfferSerializer.new(
            @settlement_offer,
            include: %i[negotiation_round team]
          ).serializable_hash, status: :created
        else
          render_errors(@settlement_offer.errors)
        end
      end

      def update
        authorize @simulation, :participate?

        # Find existing settlement offer for this team and round
        @settlement_offer = @negotiation_round.settlement_offers
                                             .find_by(team: current_user_team)

        if @settlement_offer.nil?
          return api_error(
            message: "No settlement offer found for your team in this round",
            status: :not_found
          )
        end

        # Only allow updates before deadline and if round is still active
        unless @negotiation_round.active? && Time.current <= @negotiation_round.deadline
          return api_error(
            message: "Round deadline has passed or round is completed",
            status: :unprocessable_entity
          )
        end

        if @settlement_offer.update(settlement_offer_params)
          # Re-trigger simulation dynamics for updated offer
          handle_offer_update
          
          render json: SettlementOfferSerializer.new(
            @settlement_offer,
            include: %i[negotiation_round team]
          ).serializable_hash
        else
          render_errors(@settlement_offer.errors)
        end
      end

      private

      def set_case
        @case = Case.find(params[:case_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Case not found" }, status: :not_found
      end

      def set_simulation
        @simulation = @case.simulation
        
        unless @simulation
          return api_error(
            message: "This case does not have an active simulation",
            status: :not_found
          )
        end
      end

      def set_negotiation_round
        @negotiation_round = @simulation.negotiation_rounds
                                       .find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Negotiation round not found" }, status: :not_found
      end

      def verify_team_participation
        unless current_user_team
          return api_error(
            message: "You are not assigned to a team for this case",
            status: :forbidden
          )
        end

        unless [@simulation.plaintiff_team, @simulation.defendant_team].include?(current_user_team)
          return api_error(
            message: "Your team is not participating in this simulation",
            status: :forbidden
          )
        end
      end

      def current_user_team
        @current_user_team ||= current_user.teams
                                          .joins(:case_teams)
                                          .where(case_teams: { case: @case })
                                          .first
      end

      def find_or_create_current_round
        # Find existing round or create it if it doesn't exist
        round = @simulation.negotiation_rounds
                          .find_by(round_number: @simulation.current_round)

        return round if round

        # Create new round with appropriate deadline
        deadline = calculate_round_deadline
        
        @simulation.negotiation_rounds.create!(
          round_number: @simulation.current_round,
          deadline: deadline,
          status: :active
        )
      end

      def calculate_round_deadline
        # Default 48 hours from now, but configurable via simulation settings
        hours_per_round = @simulation.simulation_config.dig("hours_per_round") || 48
        Time.current + hours_per_round.hours
      end

      def build_settlement_offer
        # Check if team already has an offer for this round
        existing_offer = @negotiation_round.settlement_offers
                                          .find_by(team: current_user_team)

        if existing_offer
          return api_error(
            message: "Your team has already submitted an offer for this round",
            status: :unprocessable_entity
          )
        end

        @negotiation_round.settlement_offers.build(
          settlement_offer_params.merge(
            team: current_user_team,
            submitted_by: current_user,
            submitted_at: Time.current
          )
        )
      end

      def handle_offer_submission
        # Apply simulation dynamics
        dynamics_service = SimulationDynamicsService.new(@simulation)
        
        # Generate client feedback
        feedback_service = ClientFeedbackService.new(@simulation)
        feedback_service.generate_feedback_for_offer!(@settlement_offer)

        # Trigger events if appropriate
        event_orchestrator = SimulationEventOrchestrator.new(@simulation)
        event_orchestrator.orchestrate_round_events!(@simulation.current_round)

        # Apply dynamic range adjustments
        dynamics_service.adjust_ranges_for_round!(@simulation.current_round)

        # Check if round should advance
        check_round_advancement
      end

      def handle_offer_update
        # Re-generate feedback for updated offer
        feedback_service = ClientFeedbackService.new(@simulation)
        feedback_service.generate_feedback_for_offer!(@settlement_offer)

        # Apply any needed range adjustments
        dynamics_service = SimulationDynamicsService.new(@simulation)
        dynamics_service.adjust_ranges_for_round!(@simulation.current_round)

        # Check if round should advance
        check_round_advancement
      end

      def check_round_advancement
        # Check if both teams have submitted and auto-advance if configured
        if @negotiation_round.both_teams_submitted?
          if @negotiation_round.settlement_reached?
            # Settlement reached - complete simulation
            @simulation.complete!
            
            # Generate settlement feedback
            feedback_service = ClientFeedbackService.new(@simulation)
            feedback_service.generate_settlement_feedback!(@negotiation_round)
          elsif @simulation.current_round >= @simulation.total_rounds
            # Final round completed without settlement - trigger arbitration
            @simulation.trigger_arbitration!
            
            # Generate arbitration feedback
            feedback_service = ClientFeedbackService.new(@simulation)
            feedback_service.generate_arbitration_feedback!
          else
            # Advance to next round if auto-advance is enabled
            if @simulation.simulation_config.dig("auto_advance_rounds")
              advance_to_next_round
            end
          end
        end
      end

      def advance_to_next_round
        return unless @simulation.can_advance_round?

        # Complete current round
        @negotiation_round.complete!

        # Advance simulation to next round
        @simulation.next_round!

        # Generate transition feedback
        feedback_service = ClientFeedbackService.new(@simulation)
        feedback_service.generate_round_transition_feedback!(
          @simulation.current_round - 1,
          @simulation.current_round
        )

        # Schedule future events for new round
        event_orchestrator = SimulationEventOrchestrator.new(@simulation)
        event_orchestrator.schedule_future_events!(@simulation.current_round)
      end

      def settlement_offer_params
        params.require(:settlement_offer).permit(
          :amount,
          :justification,
          :non_monetary_terms,
          :offer_type
        )
      end

      def render_errors(errors)
        render json: {
          errors: errors.full_messages
        }, status: :unprocessable_entity
      end
    end
  end
end