# frozen_string_literal: true

class NegotiationRound < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :simulation
  has_many :settlement_offers, dependent: :destroy
  has_many :client_feedbacks, foreign_key: :triggered_by_round, primary_key: :round_number

  # Delegated associations
  delegate :case, :plaintiff_team, :defendant_team, to: :simulation

  # Validations
  validates :round_number, presence: true,
                          numericality: { greater_than: 0 },
                          uniqueness: { scope: :simulation_id }
  validates :deadline, presence: true

  validate :deadline_in_future, on: :create
  validate :round_number_within_simulation_bounds

  # Enums
  enum :status, {
    pending: "pending",
    active: "active",
    plaintiff_submitted: "plaintiff_submitted",
    defendant_submitted: "defendant_submitted",
    both_submitted: "both_submitted",
    completed: "completed"
  }, prefix: :status

  # Scopes
  scope :active_rounds, -> { where(status: [:active, :plaintiff_submitted, :defendant_submitted, :both_submitted]) }
  scope :overdue, -> { where("deadline < ?", Time.current) }
  scope :by_round_number, -> { order(:round_number) }

  # Callbacks
  before_save :update_status_based_on_offers
  after_update :check_for_completion

  # Instance methods
  def start!
    return false unless status_pending?

    update!(status: :active, started_at: Time.current)
  end

  def plaintiff_offer
    settlement_offers.joins(:team)
                    .joins("JOIN case_teams ON teams.id = case_teams.team_id")
                    .where(case_teams: { role: :plaintiff })
                    .first
  end

  def defendant_offer
    settlement_offers.joins(:team)
                    .joins("JOIN case_teams ON teams.id = case_teams.team_id")
                    .where(case_teams: { role: :defendant })
                    .first
  end

  def has_plaintiff_offer?
    plaintiff_offer.present?
  end

  def has_defendant_offer?
    defendant_offer.present?
  end

  def both_teams_submitted?
    has_plaintiff_offer? && has_defendant_offer?
  end

  def overdue?
    deadline < Time.current
  end

  def can_complete?
    both_teams_submitted? || overdue?
  end

  def complete!
    return false unless can_complete?

    update!(status: :completed, completed_at: Time.current)
  end

  def settlement_gap
    return nil unless both_teams_submitted?

    plaintiff_amount = plaintiff_offer&.amount || 0
    defendant_amount = defendant_offer&.amount || 0

    (plaintiff_amount - defendant_amount).abs
  end

  def settlement_reached?
    return false unless both_teams_submitted?

    plaintiff_amount = plaintiff_offer&.amount || 0
    defendant_amount = defendant_offer&.amount || 0

    # Settlement reached if offers are within 5% of each other
    gap = (plaintiff_amount - defendant_amount).abs
    average = (plaintiff_amount + defendant_amount) / 2.0

    return false if average.zero?

    (gap / average) <= 0.05
  end

  def time_remaining
    return 0 if overdue?

    ((deadline - Time.current) / 1.hour).round(1)
  end

  private

  def deadline_in_future
    return unless deadline.present?

    errors.add(:deadline, "must be in the future") if deadline <= Time.current
  end

  def round_number_within_simulation_bounds
    return unless round_number.present? && simulation.present?

    if round_number > simulation.total_rounds
      errors.add(:round_number, "cannot exceed simulation total rounds")
    end
  end

  def update_status_based_on_offers
    return if status_completed?

    if both_teams_submitted?
      self.status = :both_submitted
    elsif has_plaintiff_offer? && has_defendant_offer?
      self.status = :both_submitted
    elsif has_plaintiff_offer?
      self.status = :plaintiff_submitted
    elsif has_defendant_offer?
      self.status = :defendant_submitted
    elsif status_pending?
      # Keep as pending until first offer
    else
      self.status = :active
    end
  end

  def check_for_completion
    return unless saved_change_to_status? && status_both_submitted?

    # Auto-complete if settlement reached or if this is the final round
    if settlement_reached? || round_number >= simulation.total_rounds
      complete!

      if settlement_reached?
        simulation.complete!
      elsif round_number >= simulation.total_rounds
        simulation.trigger_arbitration!
      end
    end
  end
end
