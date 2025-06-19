# frozen_string_literal: true

class ClientFeedback < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :simulation
  belongs_to :team
  belongs_to :settlement_offer, optional: true

  # Delegated associations
  delegate :case, to: :simulation

  # Validations
  validates :feedback_type, presence: true
  validates :mood_level, presence: true
  validates :satisfaction_score, presence: true,
    numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 100}
  validates :feedback_text, presence: true,
    length: {minimum: 10, maximum: 500}
  validates :triggered_by_round, presence: true,
    numericality: {greater_than: 0}

  validate :team_assigned_to_case

  # Enums
  enum :feedback_type, {
    offer_reaction: "offer_reaction",
    strategy_guidance: "strategy_guidance",
    pressure_response: "pressure_response",
    settlement_satisfaction: "settlement_satisfaction"
  }, prefix: :feedback

  enum :mood_level, {
    very_unhappy: "very_unhappy",
    unhappy: "unhappy",
    neutral: "neutral",
    satisfied: "satisfied",
    very_satisfied: "very_satisfied"
  }, prefix: :mood

  # Scopes
  scope :recent_feedback, -> { order(created_at: :desc) }
  scope :for_round, ->(round) { where(triggered_by_round: round) }
  scope :positive_feedback, -> { where(mood_level: [:satisfied, :very_satisfied]) }
  scope :negative_feedback, -> { where(mood_level: [:very_unhappy, :unhappy]) }
  scope :by_type, ->(type) { where(feedback_type: type) }

  # Instance methods
  def team_role
    case_team = team.case_teams.find_by(case: simulation.case)
    case_team&.role
  end

  def is_plaintiff_feedback?
    team_role == "plaintiff"
  end

  def is_defendant_feedback?
    team_role == "defendant"
  end

  def mood_emoji
    case mood_level
    when "very_unhappy" then "😡"
    when "unhappy" then "😠"
    when "neutral" then "😐"
    when "satisfied" then "😊"
    when "very_satisfied" then "😁"
    else "😐"
    end
  end

  def mood_description
    case mood_level
    when "very_unhappy" then "Very Frustrated"
    when "unhappy" then "Concerned"
    when "neutral" then "Neutral"
    when "satisfied" then "Pleased"
    when "very_satisfied" then "Very Happy"
    else "Unknown"
    end
  end

  def formatted_message
    "#{mood_emoji} **#{mood_description}** (#{satisfaction_score}%)\n\n#{feedback_text}"
  end

  def impact_on_future_rounds
    case mood_level
    when "very_unhappy"
      "Client may push for more aggressive strategy"
    when "unhappy"
      "Client requests strategy adjustment"
    when "neutral"
      "Client maintains current expectations"
    when "satisfied"
      "Client confident in current approach"
    when "very_satisfied"
      "Client very supportive of strategy"
    end
  end

  # Class methods for feedback generation
  def self.generate_offer_reaction(simulation, team, settlement_offer)
    mood, satisfaction, message = calculate_offer_reaction(simulation, team, settlement_offer)

    create!(
      simulation: simulation,
      team: team,
      settlement_offer: settlement_offer,
      feedback_type: :offer_reaction,
      mood_level: mood,
      satisfaction_score: satisfaction,
      feedback_text: message,
      triggered_by_round: settlement_offer.round_number
    )
  end

  def self.generate_pressure_response(simulation, team, round_number, event_type)
    mood, satisfaction, message = calculate_pressure_response(simulation, team, event_type)

    create!(
      simulation: simulation,
      team: team,
      feedback_type: :pressure_response,
      mood_level: mood,
      satisfaction_score: satisfaction,
      feedback_text: message,
      triggered_by_round: round_number
    )
  end

  def self.generate_strategy_guidance(simulation, team, round_number)
    mood, satisfaction, message = calculate_strategy_guidance(simulation, team, round_number)

    create!(
      simulation: simulation,
      team: team,
      feedback_type: :strategy_guidance,
      mood_level: mood,
      satisfaction_score: satisfaction,
      feedback_text: message,
      triggered_by_round: round_number
    )
  end

  private

  def team_assigned_to_case
    return unless team.present? && simulation.present?

    unless team.case_teams.exists?(case: simulation.case)
      errors.add(:team, "is not assigned to this case")
    end
  end

  # Class methods for feedback calculation
  def self.calculate_offer_reaction(simulation, team, settlement_offer)
    case_team = team.case_teams.find_by(case: simulation.case)
    return ["neutral", 50, "Unable to assess offer"] unless case_team

    if case_team.role == "plaintiff"
      calculate_plaintiff_reaction(simulation, settlement_offer)
    else
      calculate_defendant_reaction(simulation, settlement_offer)
    end
  end

  def self.calculate_plaintiff_reaction(simulation, offer)
    amount = offer.amount
    min_acceptable = simulation.plaintiff_min_acceptable
    ideal = simulation.plaintiff_ideal

    if amount >= ideal
      ["very_satisfied", 95, "Client thrilled with this ambitious opening position. This sets us up well for negotiations."]
    elsif amount >= min_acceptable * 1.2
      ["satisfied", 80, "Client pleased with this reasonable demand. Shows we're serious but willing to negotiate."]
    elsif amount >= min_acceptable
      ["neutral", 60, "Client cautiously optimistic. This is acceptable but we may need to justify the amount carefully."]
    elsif amount >= min_acceptable * 0.8
      ["unhappy", 40, "Client concerned this demand may be too low. We should consider our bargaining position."]
    else
      ["very_unhappy", 20, "Client frustrated with this weak opening. This undervalues the harm suffered."]
    end
  end

  def self.calculate_defendant_reaction(simulation, offer)
    amount = offer.amount
    max_acceptable = simulation.defendant_max_acceptable
    ideal = simulation.defendant_ideal

    if amount <= ideal
      ["very_satisfied", 95, "Client very pleased with this conservative offer. This shows we can resolve this efficiently."]
    elsif amount <= ideal * 1.5
      ["satisfied", 80, "Client satisfied with this measured approach. We're positioned well for settlement discussions."]
    elsif amount <= max_acceptable
      ["neutral", 60, "Client willing to consider this amount but hopes to negotiate downward."]
    elsif amount <= max_acceptable * 1.2
      ["unhappy", 40, "Client concerned this offer is getting expensive but still within range."]
    else
      ["very_unhappy", 20, "Client worried this offer will be seen as insulting and damage negotiations."]
    end
  end

  def self.calculate_pressure_response(simulation, team, event_type)
    case_team = team.case_teams.find_by(case: simulation.case)
    base_messages = {
      "media_attention" => {
        "plaintiff" => "Media coverage puts additional pressure on the company to settle fairly.",
        "defendant" => "Media attention increases urgency to resolve this matter quickly and quietly."
      },
      "witness_change" => {
        "plaintiff" => "New witness strengthens our position significantly.",
        "defendant" => "Additional testimony complicates our defense strategy."
      },
      "ipo_delay" => {
        "plaintiff" => "Company's IPO delay shows the serious impact of this case.",
        "defendant" => "IPO delay creates significant financial pressure to settle quickly."
      },
      "court_deadline" => {
        "plaintiff" => "Expedited trial date increases pressure on both sides to settle.",
        "defendant" => "Trial scheduling creates time pressure to reach agreement."
      }
    }

    role = case_team&.role || "plaintiff"
    message = base_messages.dig(event_type, role) || "External pressures are affecting the case dynamics."

    if role == "plaintiff"
      ["satisfied", 75, message]
    else
      ["unhappy", 45, message]
    end
  end

  def self.calculate_strategy_guidance(simulation, team, round_number)
    team.case_teams.find_by(case: simulation.case)

    if round_number <= 2
      mood = "neutral"
      satisfaction = 60
      message = "Early rounds are about establishing positions. Focus on clear justifications and reasonable movement."
    elsif round_number <= 4
      mood = "neutral"
      satisfaction = 55
      message = "Mid-negotiation requires careful strategy. Consider creative non-monetary terms to bridge gaps."
    else
      mood = "unhappy"
      satisfaction = 45
      message = "Time pressure mounting. Client wants resolution soon. Consider final positioning carefully."
    end

    [mood, satisfaction, message]
  end
end
