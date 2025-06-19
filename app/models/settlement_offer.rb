# frozen_string_literal: true

class SettlementOffer < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :negotiation_round
  belongs_to :team
  belongs_to :submitted_by, class_name: "User"
  belongs_to :scored_by, class_name: "User", optional: true
  has_many :client_feedbacks, dependent: :nullify

  # Delegated associations
  delegate :simulation, :case, to: :negotiation_round
  delegate :round_number, to: :negotiation_round

  # Validations
  validates :amount, presence: true,
    numericality: {greater_than_or_equal_to: 0}
  validates :justification, presence: true,
    length: {minimum: 50, maximum: 2000}
  validates :submitted_at, presence: true
  validates :team_id, uniqueness: {scope: :negotiation_round_id,
                                   message: "can only submit one offer per round"}

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
  scope :plaintiff_offers, -> {
    joins(:team)
      .joins("JOIN case_teams ON teams.id = case_teams.team_id")
      .where(case_teams: {role: :plaintiff})
  }
  scope :defendant_offers, -> {
    joins(:team)
      .joins("JOIN case_teams ON teams.id = case_teams.team_id")
      .where(case_teams: {role: :defendant})
  }
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
      &.where(negotiation_rounds: {simulation: simulation})
      &.where("negotiation_rounds.round_number <= ?", round_number)
      &.order("negotiation_rounds.round_number DESC, settlement_offers.submitted_at DESC")
      &.first
  end

  def movement_from_previous
    previous_offer = team.settlement_offers
      .joins(:negotiation_round)
      .where(negotiation_rounds: {simulation: simulation})
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

  # Enhanced validation using the new range validation service
  def client_range_validation
    @client_range_validation ||= begin
      validation_service = ClientRangeValidationService.new(simulation)
      validation_service.validate_offer(team, amount)
    end
  end

  # Check if offer is within client's "satisfied" range
  def within_satisfied_range?
    client_range_validation.satisfaction_score >= 70
  end

  # Get client pressure level for this offer
  def client_pressure_level
    client_range_validation.pressure_level
  end

  # Get client mood for this offer
  def client_mood
    client_range_validation.mood
  end

  # Check if offer positioning is strong
  def strong_positioning?
    [:strong_position, :excellent_position, :ideal_amount].include?(
      client_range_validation.positioning
    )
  end

  # Check if offer is problematic for client
  def problematic_positioning?
    [:too_aggressive, :below_minimum, :exceeds_maximum, :unacceptable_exposure].include?(
      client_range_validation.positioning
    )
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

    {total_score: score, breakdown: factors}
  end

  def update_quality_score!
    assessment = quality_assessment
    update!(quality_score: assessment[:total_score])
    calculate_final_quality_score!
  end

  def calculate_instructor_quality_score!
    return unless has_instructor_scores?

    total = [
      instructor_legal_reasoning_score,
      instructor_factual_analysis_score,
      instructor_strategic_thinking_score,
      instructor_professionalism_score,
      instructor_creativity_score
    ].compact.sum

    update!(instructor_quality_score: total)
    calculate_final_quality_score!
  end

  def calculate_final_quality_score!
    final_score = if instructor_quality_score.present?
      # Use instructor score when available (weighted 70% instructor, 30% automatic)
      (instructor_quality_score * 0.7) + ((quality_score || 0) * 0.3)
    else
      # Use automatic assessment only
      quality_score || 0
    end

    update!(final_quality_score: final_score.round)
  end

  def has_instructor_scores?
    [
      instructor_legal_reasoning_score,
      instructor_factual_analysis_score,
      instructor_strategic_thinking_score,
      instructor_professionalism_score,
      instructor_creativity_score
    ].any?(&:present?)
  end

  def instructor_scoring_complete?
    [
      instructor_legal_reasoning_score,
      instructor_factual_analysis_score,
      instructor_strategic_thinking_score,
      instructor_professionalism_score,
      instructor_creativity_score
    ].all?(&:present?)
  end

  def instructor_assessment_breakdown
    return {} unless has_instructor_scores?

    {
      legal_reasoning: {
        score: instructor_legal_reasoning_score,
        percentage: instructor_legal_reasoning_score ? (instructor_legal_reasoning_score / 25.0 * 100).round(1) : nil
      },
      factual_analysis: {
        score: instructor_factual_analysis_score,
        percentage: instructor_factual_analysis_score ? (instructor_factual_analysis_score / 25.0 * 100).round(1) : nil
      },
      strategic_thinking: {
        score: instructor_strategic_thinking_score,
        percentage: instructor_strategic_thinking_score ? (instructor_strategic_thinking_score / 25.0 * 100).round(1) : nil
      },
      professionalism: {
        score: instructor_professionalism_score,
        percentage: instructor_professionalism_score ? (instructor_professionalism_score / 25.0 * 100).round(1) : nil
      },
      creativity: {
        score: instructor_creativity_score,
        percentage: instructor_creativity_score ? (instructor_creativity_score / 25.0 * 100).round(1) : nil
      },
      total_score: instructor_quality_score,
      total_percentage: instructor_quality_score ? (instructor_quality_score / 125.0 * 100).round(1) : nil
    }
  end

  private

  def set_offer_type
    self.offer_type = if round_number == 1
      :initial_demand
    elsif round_number >= simulation.total_rounds
      :final_offer
    else
      :counteroffer
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
    # Generate client feedback using the enhanced service
    feedback_service = ClientFeedbackService.new(simulation)
    feedback_service.generate_feedback_for_offer!(self)
  rescue => e
    Rails.logger.error "Failed to generate client feedback for settlement offer #{id}: #{e.message}"
    # Don't let feedback generation failure break offer creation
  end

  def update_round_status
    negotiation_round.reload
    # The round will update its own status based on submitted offers
    negotiation_round.save!
  end
end
