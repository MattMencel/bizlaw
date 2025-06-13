# frozen_string_literal: true

class NegotiationRoundSerializer
  include JSONAPI::Serializer

  attributes :round_number, :status, :deadline, :started_at, :completed_at,
             :created_at, :updated_at

  # Computed attributes
  attribute :time_remaining do |round|
    round.time_remaining
  end

  attribute :overdue do |round|
    round.overdue?
  end

  attribute :both_teams_submitted do |round|
    round.both_teams_submitted?
  end

  attribute :settlement_reached do |round|
    round.settlement_reached?
  end

  attribute :settlement_gap do |round|
    round.settlement_gap
  end

  # Associations
  has_many :settlement_offers
  belongs_to :simulation

  # Conditional attributes based on user permissions
  attribute :plaintiff_submitted do |round, params|
    round.has_plaintiff_offer?
  end

  attribute :defendant_submitted do |round, params|
    round.has_defendant_offer?
  end

  # Team-specific offer visibility
  attribute :team_offer do |round, params|
    next nil unless params[:current_user]

    user_team = params[:current_user].teams
                                    .joins(:case_teams)
                                    .where(case_teams: { case: round.case })
                                    .first

    next nil unless user_team

    case_team = user_team.case_teams.find_by(case: round.case)
    team_role = case_team&.role

    if team_role == "plaintiff"
      round.plaintiff_offer
    elsif team_role == "defendant"
      round.defendant_offer
    end
  end

  attribute :opposing_offer_summary do |round, params|
    next nil unless params[:current_user]

    user_team = params[:current_user].teams
                                    .joins(:case_teams)
                                    .where(case_teams: { case: round.case })
                                    .first

    next nil unless user_team

    case_team = user_team.case_teams.find_by(case: round.case)
    team_role = case_team&.role

    opposing_offer = if team_role == "plaintiff"
                      round.defendant_offer
                    elsif team_role == "defendant"
                      round.plaintiff_offer
                    end

    next nil unless opposing_offer

    # Return limited info about opposing offer
    {
      has_offer: true,
      amount: opposing_offer.amount,
      submitted_at: opposing_offer.submitted_at,
      # Don't reveal justification or non-monetary terms
      non_monetary_terms_present: opposing_offer.non_monetary_terms.present?
    }
  end
end