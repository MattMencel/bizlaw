# frozen_string_literal: true

class SettlementOfferSerializer
  include JSONAPI::Serializer

  attributes :amount, :justification, :non_monetary_terms, :offer_type,
    :submitted_at, :quality_score, :created_at, :updated_at

  # Computed attributes
  attribute :within_client_expectations do |offer|
    offer.within_client_expectations?
  end

  attribute :movement_from_previous do |offer|
    offer.movement_from_previous
  end

  attribute :gap_with_opposing_offer do |offer|
    offer.gap_with_opposing_offer
  end

  attribute :quality_assessment do |offer|
    offer.quality_assessment
  end

  # Associations
  belongs_to :negotiation_round
  belongs_to :team
  belongs_to :submitted_by, serializer: UserSerializer

  # Team role information
  attribute :team_role do |offer|
    offer.team_role
  end

  # Strategic analysis (visible only to the submitting team)
  attribute :strategic_analysis do |offer, params|
    next nil unless params[:current_user]

    # Only show strategic analysis to the team that submitted this offer
    user_team = params[:current_user].teams
      .joins(:case_teams)
      .where(case_teams: {case: offer.case})
      .first

    next nil unless user_team == offer.team

    {
      quality_breakdown: offer.quality_assessment,
      strategic_position: offer.within_client_expectations? ? "favorable" : "needs_adjustment",
      movement_analysis: analyze_movement(offer),
      recommendations: generate_recommendations(offer)
    }
  end

  private

  def self.analyze_movement(offer)
    movement = offer.movement_from_previous
    return "initial_offer" unless movement

    if movement.abs < 5000
      "minimal_movement"
    elsif movement.abs < 25000
      "moderate_movement"
    else
      "significant_movement"
    end
  end

  def self.generate_recommendations(offer)
    recommendations = []

    # Quality-based recommendations
    quality = offer.quality_assessment
    if quality[:total_score] < 60
      recommendations << "Consider strengthening legal justification"
    end

    if quality[:breakdown][:creativity] < 15
      recommendations << "Explore creative non-monetary terms"
    end

    # Strategic positioning recommendations
    unless offer.within_client_expectations?
      recommendations << if offer.is_plaintiff_offer?
        "Consider if demand aligns with client's minimum expectations"
      else
        "Verify offer stays within authorized settlement range"
      end
    end

    # Gap-based recommendations
    gap = offer.gap_with_opposing_offer
    if gap && gap > 100000
      recommendations << "Large gap suggests need for strategic adjustment"
    end

    recommendations
  end

  private_class_method :analyze_movement, :generate_recommendations
end
