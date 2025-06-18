# frozen_string_literal: true

class Simulation < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :case
  has_many :negotiation_rounds, dependent: :destroy
  has_many :settlement_offers, through: :negotiation_rounds
  has_many :simulation_events, dependent: :destroy
  has_many :performance_scores, dependent: :destroy
  has_many :client_feedbacks, dependent: :destroy
  has_one :arbitration_outcome, dependent: :destroy
  has_many :evidence_releases, dependent: :destroy

  # Delegated associations through case
  delegate :plaintiff_team, :defendant_team, :assigned_teams, to: :case

  # Validations
  validates :start_date, presence: true
  validates :total_rounds, presence: true,
                          numericality: { greater_than: 0, less_than_or_equal_to: 10 }
  validates :current_round, presence: true,
                           numericality: { greater_than_or_equal_to: 1 }
  validates :plaintiff_min_acceptable, presence: true,
                                      numericality: { greater_than: 0 }
  validates :plaintiff_ideal, presence: true,
                             numericality: { greater_than: 0 }
  validates :defendant_max_acceptable, presence: true,
                                      numericality: { greater_than: 0 }
  validates :defendant_ideal, presence: true,
                             numericality: { greater_than_or_equal_to: 0 }
  validates :simulation_config, presence: true

  validate :current_round_within_total_rounds
  validate :plaintiff_amounts_logical
  validate :defendant_amounts_logical

  # Enums
  enum :status, {
    setup: "setup",
    active: "active",
    paused: "paused",
    completed: "completed",
    arbitration: "arbitration"
  }, prefix: :status

  enum :pressure_escalation_rate, {
    low: "low",
    moderate: "moderate",
    high: "high"
  }, prefix: :pressure

  # Scopes
  scope :active_simulations, -> { where(status: [ :active, :paused ]) }
  scope :completed_simulations, -> { where(status: [ :completed, :arbitration ]) }
  scope :ready_for_next_round, -> { where.not(status: [ :setup, :completed, :arbitration ]) }

  # Instance methods
  def active?
    status_active? || status_paused?
  end

  def can_advance_round?
    return false unless active?
    return false if current_round >= total_rounds

    current_negotiation_round&.status_completed?
  end

  def current_negotiation_round
    negotiation_rounds.find_by(round_number: current_round)
  end

  def next_round!
    return false unless can_advance_round?

    self.current_round += 1
    save!
  end

  def complete!
    update!(status: :completed, end_date: Time.current)
  end

  def trigger_arbitration!
    update!(status: :arbitration, end_date: Time.current)
  end

  def settlement_reached?
    settlement_offers.joins(:negotiation_round)
                    .where(negotiation_rounds: { status: :completed })
                    .exists?
  end

  def should_trigger_events?
    auto_events_enabled? && active?
  end

  def current_phase
    case status
    when "setup"
      "Preparation"
    when "active"
      "Negotiation"
    when "paused"
      "Paused"
    when "completed"
      "Completed"
    when "arbitration"
      "Arbitration"
    else
      "Unknown"
    end
  end

  private

  def current_round_within_total_rounds
    return unless current_round.present? && total_rounds.present?

    errors.add(:current_round, "cannot be greater than total rounds") if current_round > total_rounds
  end

  def plaintiff_amounts_logical
    return unless plaintiff_min_acceptable.present? && plaintiff_ideal.present?

    if plaintiff_min_acceptable > plaintiff_ideal
      errors.add(:plaintiff_min_acceptable, "cannot be greater than ideal amount")
    end
  end

  def defendant_amounts_logical
    return unless defendant_ideal.present? && defendant_max_acceptable.present?

    if defendant_ideal > defendant_max_acceptable
      errors.add(:defendant_ideal, "cannot be greater than maximum acceptable amount")
    end
  end
end
