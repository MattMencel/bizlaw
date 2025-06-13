# frozen_string_literal: true

class Api::V1::ArgumentQualityController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_case
  before_action :set_settlement_offer, only: [:show, :update]
  before_action :ensure_instructor_or_admin

  # GET /api/v1/cases/:case_id/argument_quality
  # List all settlement offers in the case with their quality scores
  def index
    @settlement_offers = @case.simulation.settlement_offers
                              .includes(:team, :negotiation_round, :submitted_by)
                              .joins(:negotiation_round)
                              .order("negotiation_rounds.round_number ASC, settlement_offers.submitted_at ASC")

    render json: {
      data: @settlement_offers.map do |offer|
        {
          id: offer.id,
          round_number: offer.round_number,
          team_name: offer.team.name,
          team_role: offer.team_role,
          amount: offer.amount,
          submitted_at: offer.submitted_at,
          submitted_by: offer.submitted_by.full_name,
          justification: offer.justification,
          non_monetary_terms: offer.non_monetary_terms,
          automatic_quality_score: offer.quality_score,
          instructor_quality_score: offer.instructor_quality_score,
          final_quality_score: offer.final_quality_score,
          quality_breakdown: offer.quality_assessment,
          instructor_feedback: offer.instructor_feedback
        }
      end,
      meta: {
        total_offers: @settlement_offers.count,
        average_quality: @settlement_offers.average(:final_quality_score)&.round(1)
      }
    }
  end

  # GET /api/v1/cases/:case_id/argument_quality/:id
  # Get detailed quality assessment for a specific settlement offer
  def show
    render json: {
      data: {
        id: @settlement_offer.id,
        round_number: @settlement_offer.round_number,
        team_name: @settlement_offer.team.name,
        team_role: @settlement_offer.team_role,
        amount: @settlement_offer.amount,
        submitted_at: @settlement_offer.submitted_at,
        submitted_by: @settlement_offer.submitted_by.full_name,
        justification: @settlement_offer.justification,
        non_monetary_terms: @settlement_offer.non_monetary_terms,
        automatic_assessment: @settlement_offer.quality_assessment,
        instructor_scores: {
          legal_reasoning: @settlement_offer.instructor_legal_reasoning_score,
          factual_analysis: @settlement_offer.instructor_factual_analysis_score,
          strategic_thinking: @settlement_offer.instructor_strategic_thinking_score,
          professionalism: @settlement_offer.instructor_professionalism_score,
          creativity: @settlement_offer.instructor_creativity_score,
          overall_score: @settlement_offer.instructor_quality_score,
          feedback: @settlement_offer.instructor_feedback
        },
        final_quality_score: @settlement_offer.final_quality_score,
        simulation_impact: calculate_simulation_impact
      }
    }
  end

  # PUT /api/v1/cases/:case_id/argument_quality/:id
  # Update instructor quality scores for a settlement offer
  def update
    scoring_params = argument_quality_params

    # Validate individual scores
    %w[legal_reasoning factual_analysis strategic_thinking professionalism creativity].each do |category|
      score = scoring_params["instructor_#{category}_score"]
      if score.present? && (score < 0 || score > 25)
        return render json: { 
          error: "#{category.humanize} score must be between 0 and 25" 
        }, status: :unprocessable_entity
      end
    end

    begin
      ActiveRecord::Base.transaction do
        # Update individual category scores
        @settlement_offer.update!(
          instructor_legal_reasoning_score: scoring_params[:instructor_legal_reasoning_score],
          instructor_factual_analysis_score: scoring_params[:instructor_factual_analysis_score],
          instructor_strategic_thinking_score: scoring_params[:instructor_strategic_thinking_score],
          instructor_professionalism_score: scoring_params[:instructor_professionalism_score],
          instructor_creativity_score: scoring_params[:instructor_creativity_score],
          instructor_feedback: scoring_params[:instructor_feedback],
          scored_by: current_user,
          scored_at: Time.current
        )

        # Calculate and update overall instructor score
        @settlement_offer.calculate_instructor_quality_score!

        # Update simulation dynamics based on new quality scores
        update_simulation_dynamics!
        
        render json: {
          data: {
            id: @settlement_offer.id,
            instructor_quality_score: @settlement_offer.instructor_quality_score,
            final_quality_score: @settlement_offer.final_quality_score,
            simulation_impact: calculate_simulation_impact
          },
          message: "Argument quality scores updated successfully"
        }
      end
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/cases/:case_id/argument_quality/rubric
  # Get the scoring rubric for instructors
  def rubric
    render json: {
      data: {
        categories: {
          legal_reasoning: {
            max_score: 25,
            description: "Analysis of relevant laws, statutes, and precedents",
            criteria: [
              "Identifies relevant legal principles (5 pts)",
              "Applies law to facts accurately (5 pts)",
              "Cites appropriate precedents (5 pts)",
              "Demonstrates legal reasoning (5 pts)",
              "Addresses counterarguments (5 pts)"
            ]
          },
          factual_analysis: {
            max_score: 25,
            description: "Use of case facts and evidence",
            criteria: [
              "Accurately summarizes key facts (5 pts)",
              "Identifies strengths and weaknesses (5 pts)",
              "Uses evidence effectively (5 pts)",
              "Addresses factual disputes (5 pts)",
              "Demonstrates thorough case knowledge (5 pts)"
            ]
          },
          strategic_thinking: {
            max_score: 25,
            description: "Negotiation strategy and positioning",
            criteria: [
              "Shows understanding of position (5 pts)",
              "Demonstrates strategic planning (5 pts)",
              "Considers opponent's perspective (5 pts)",
              "Adapts to negotiation dynamics (5 pts)",
              "Plans for future rounds (5 pts)"
            ]
          },
          professionalism: {
            max_score: 25,
            description: "Professional communication and ethics",
            criteria: [
              "Uses professional language (5 pts)",
              "Maintains respectful tone (5 pts)",
              "Follows ethical guidelines (5 pts)",
              "Organizes arguments clearly (5 pts)",
              "Demonstrates client advocacy (5 pts)"
            ]
          },
          creativity: {
            max_score: 25,
            description: "Innovation in non-monetary terms and solutions",
            criteria: [
              "Proposes creative solutions (5 pts)",
              "Addresses client interests (5 pts)",
              "Considers implementation feasibility (5 pts)",
              "Shows original thinking (5 pts)",
              "Balances all party interests (5 pts)"
            ]
          }
        },
        total_max_score: 125,
        grading_scale: {
          "A (90-100%)": "Outstanding argument quality with excellent legal reasoning and creativity",
          "B (80-89%)": "Good argument quality with solid legal foundation and reasonable strategy",
          "C (70-79%)": "Adequate argument quality meeting basic requirements",
          "D (60-69%)": "Below average argument quality with significant weaknesses",
          "F (0-59%)": "Poor argument quality requiring substantial improvement"
        }
      }
    }
  end

  private

  def set_case
    @case = Case.find(params[:case_id])
    authorize @case, :show?
  end

  def set_settlement_offer
    @settlement_offer = @case.simulation.settlement_offers.find(params[:id])
  end

  def ensure_instructor_or_admin
    unless current_user.role_instructor? || current_user.role_admin?
      render json: { error: "Access denied. Instructor or admin role required." }, status: :forbidden
    end
  end

  def argument_quality_params
    params.require(:argument_quality).permit(
      :instructor_legal_reasoning_score,
      :instructor_factual_analysis_score,
      :instructor_strategic_thinking_score,
      :instructor_professionalism_score,
      :instructor_creativity_score,
      :instructor_feedback
    )
  end

  def calculate_simulation_impact
    return {} unless @settlement_offer.instructor_quality_score.present?

    dynamics_service = SimulationDynamicsService.new(@case.simulation)
    
    {
      current_ranges: {
        plaintiff_range: {
          min: @case.simulation.plaintiff_min_acceptable,
          ideal: @case.simulation.plaintiff_ideal
        },
        defendant_range: {
          ideal: @case.simulation.defendant_ideal,
          max: @case.simulation.defendant_max_acceptable
        }
      },
      quality_impact: dynamics_service.calculate_quality_impact(@settlement_offer),
      pressure_adjustments: dynamics_service.current_pressure_factors
    }
  end

  def update_simulation_dynamics!
    dynamics_service = SimulationDynamicsService.new(@case.simulation)
    dynamics_service.apply_argument_quality_adjustments!(@settlement_offer)
  end
end