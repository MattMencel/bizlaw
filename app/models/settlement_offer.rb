# frozen_string_literal: true

class SettlementOffer < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :negotiation_round
  belongs_to :team
  belongs_to :submitted_by, class_name: "User"
  has_many :client_feedbacks, dependent: :nullify

  # Delegated associations
  delegate :simulation, :case, to: :negotiation_round
  delegate :round_number, to: :negotiation_round

  # Validations
  validates :amount, presence: true,
                    numericality: { greater_than_or_equal_to: 0 }
  validates :justification, presence: true,
                           length: { minimum: 50, maximum: 2000 }
  validates :submitted_at, presence: true
  validates :team_id, uniqueness: { scope: :negotiation_round_id,
                                   message: "can only submit one offer per round" }

  validate :team_assigned_to_case
  validate :offer_submitted_within_deadline
  validate :amount_within_reasonable_bounds

  # Enums
  enum :offer_type, {
    initial_demand: "initial_demand",
    counteroffer: "counteroffer",
    final_offer: "final_offer"
  }, prefix: :offer

  # Scopes
  scope :plaintiff_offers, -> { joins(:team)
                                 .joins("JOIN case_teams ON teams.id = case_teams.team_id")
                                 .where(case_teams: { role: :plaintiff }) }
  scope :defendant_offers, -> { joins(:team)
                                 .joins("JOIN case_teams ON teams.id = case_teams.team_id")
                                 .where(case_teams: { role: :defendant }) }
  scope :by_submission_time, -> { order(:submitted_at) }
  scope :recent_first, -> { order(submitted_at: :desc) }

  # Callbacks
  before_create :set_offer_type
  after_create :trigger_client_feedback
  after_create :update_round_status

  # Instance methods
  def team_role
    case_team = team.case_teams.find_by(case: self.case)
    case_team&.role
  end

  def is_plaintiff_offer?
    team_role == "plaintiff"
  end

  def is_defendant_offer?
    team_role == "defendant"
  end

  def opposing_team
    if is_plaintiff_offer?
      simulation.defendant_team
    else
      simulation.plaintiff_team
    end
  end

  def latest_opposing_offer
    opposing_team&.settlement_offers
                 &.joins(:negotiation_round)
                 &.where(negotiation_rounds: { simulation: simulation })
                 &.where("negotiation_rounds.round_number <= ?", round_number)
                 &.order("negotiation_rounds.round_number DESC, settlement_offers.submitted_at DESC")
                 &.first
  end

  def movement_from_previous
    previous_offer = team.settlement_offers
                        .joins(:negotiation_round)
                        .where(negotiation_rounds: { simulation: simulation })
                        .where("negotiation_rounds.round_number < ?", round_number)
                        .order("negotiation_rounds.round_number DESC")
                        .first

    return nil unless previous_offer

    amount - previous_offer.amount
  end

  def gap_with_opposing_offer
    opposing = latest_opposing_offer
    return nil unless opposing

    (amount - opposing.amount).abs
  end

  def within_client_expectations?
    return false unless simulation

    if is_plaintiff_offer?
      amount >= simulation.plaintiff_min_acceptable
    else
      amount <= simulation.defendant_max_acceptable
    end
  end

  def quality_assessment
    score = 0
    factors = {}

    # Justification quality (0-25 points)
    justification_score = calculate_justification_quality
    score += justification_score
    factors[:justification] = justification_score

    # Client expectation alignment (0-25 points)
    expectation_score = within_client_expectations? ? 25 : 0
    score += expectation_score
    factors[:client_expectations] = expectation_score

    # Strategic positioning (0-25 points)
    strategic_score = calculate_strategic_positioning
    score += strategic_score
    factors[:strategic_positioning] = strategic_score

    # Non-monetary terms creativity (0-25 points)
    creative_score = calculate_creativity_score
    score += creative_score
    factors[:creativity] = creative_score

    { total_score: score, breakdown: factors }
  end

  def update_quality_score!
    assessment = quality_assessment
    update!(quality_score: assessment[:total_score])
  end

  private

  def set_offer_type
    if round_number == 1
      self.offer_type = :initial_demand
    elsif round_number >= simulation.total_rounds
      self.offer_type = :final_offer
    else
      self.offer_type = :counteroffer
    end
  end

  def team_assigned_to_case
    return unless team.present? && negotiation_round.present?

    unless team.case_teams.exists?(case: self.case)
      errors.add(:team, "is not assigned to this case")
    end
  end

  def offer_submitted_within_deadline
    return unless submitted_at.present? && negotiation_round.present?

    if submitted_at > negotiation_round.deadline
      errors.add(:submitted_at, "cannot be after round deadline")
    end
  end

  def amount_within_reasonable_bounds
    return unless amount.present? && simulation.present?

    max_reasonable = [simulation.plaintiff_ideal, simulation.defendant_max_acceptable].max * 2

    if amount > max_reasonable
      errors.add(:amount, "is unreasonably high for this case")
    end
  end

  def calculate_justification_quality
    return 0 unless justification.present?

    score = 0

    # Length and detail (0-10 points)
    if justification.length >= 200
      score += 10
    elsif justification.length >= 100
      score += 5
    end

    # Legal reasoning keywords (0-10 points)
    legal_terms = %w[damages compensation liability negligence precedent statute evidence testimony]
    legal_score = legal_terms.count { |term| justification.downcase.include?(term) }
    score += [legal_score * 2, 10].min

    # Professional tone (0-5 points)
    if justification.match?(/\b(respectfully|pursuant|whereas|therefore)\b/i)
      score += 5
    end

    [score, 25].min
  end

  def calculate_strategic_positioning
    return 15 unless latest_opposing_offer # Default score for first offer

    gap = gap_with_opposing_offer
    return 25 if gap.nil?

    # Smaller gaps get higher scores
    if gap < 10000
      25
    elsif gap < 50000
      20
    elsif gap < 100000
      15
    elsif gap < 200000
      10
    else
      5
    end
  end

  def calculate_creativity_score
    return 0 unless non_monetary_terms.present?

    score = 0

    # Base score for having non-monetary terms
    score += 10

    # Additional score for specific creative elements
    creative_elements = %w[apology training policy confidentiality reference mediation]
    element_score = creative_elements.count { |element| non_monetary_terms.downcase.include?(element) }
    score += [element_score * 3, 15].min

    [score, 25].min
  end

  def trigger_client_feedback
    # This will be implemented in a service class
    # ClientFeedbackService.new(self).generate_feedback
  end

  def update_round_status
    negotiation_round.reload
    # The round will update its own status based on submitted offers
    negotiation_round.save!
  end
end
