# frozen_string_literal: true

class Simulation < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :case
  has_many :teams, dependent: :destroy
  has_many :negotiation_rounds, dependent: :destroy
  has_many :settlement_offers, through: :negotiation_rounds
  has_many :simulation_events, dependent: :destroy
  has_many :performance_scores, dependent: :destroy
  has_many :client_feedbacks, dependent: :destroy
  has_one :arbitration_outcome, dependent: :destroy
  has_many :evidence_releases, dependent: :destroy

  # Team role associations
  has_many :plaintiff_teams, -> { where(role: :plaintiff) }, class_name: "Team"
  has_many :defendant_teams, -> { where(role: :defendant) }, class_name: "Team"

  # Backward compatibility methods
  def plaintiff_team
    plaintiff_teams.first
  end

  def defendant_team
    defendant_teams.first
  end

  # Delegated associations through case
  delegate :course, to: :case

  # Name and display methods
  def display_name
    return name if name.present?
    default_name
  end

  def default_name
    sequence_number = self.case.simulations.where("created_at <= ?", created_at).count
    "Simulation #{sequence_number}"
  end

  def short_id
    id.to_s.first(8)
  end

  # Validations
  validates :start_date, presence: true, if: -> { status_active? || status_paused? || status_completed? || status_arbitration? }
  validates :total_rounds, presence: true,
    numericality: {greater_than: 0, less_than_or_equal_to: 10}
  validates :current_round, presence: true,
    numericality: {greater_than_or_equal_to: 1}

  # Financial validations only required when not in setup
  validates :plaintiff_min_acceptable, presence: true,
    numericality: {greater_than: 0},
    if: -> { status_active? || status_paused? || status_completed? || status_arbitration? }
  validates :plaintiff_ideal, presence: true,
    numericality: {greater_than: 0},
    if: -> { status_active? || status_paused? || status_completed? || status_arbitration? }
  validates :defendant_max_acceptable, presence: true,
    numericality: {greater_than: 0},
    if: -> { status_active? || status_paused? || status_completed? || status_arbitration? }
  validates :defendant_ideal, presence: true,
    numericality: {greater_than_or_equal_to: 0},
    if: -> { status_active? || status_paused? || status_completed? || status_arbitration? }
  validates :simulation_config, presence: true
  validate :has_plaintiff_teams, if: -> { status_active? || status_paused? || status_completed? || status_arbitration? }
  validate :has_defendant_teams, if: -> { status_active? || status_paused? || status_completed? || status_arbitration? }

  validate :current_round_within_total_rounds
  validate :plaintiff_amounts_logical
  validate :defendant_amounts_logical
  validate :settlement_mathematically_possible

  # Callbacks
  after_create :create_default_teams

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
  scope :active_simulations, -> { where(status: [:active, :paused]) }
  scope :completed_simulations, -> { where(status: [:completed, :arbitration]) }
  scope :ready_for_next_round, -> { where.not(status: [:setup, :completed, :arbitration]) }

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
      .where(negotiation_rounds: {status: :completed})
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

  def has_plaintiff_teams
    unless plaintiff_teams.exists?
      errors.add(:base, "must have at least one plaintiff team")
    end
  end

  def has_defendant_teams
    unless defendant_teams.exists?
      errors.add(:base, "must have at least one defendant team")
    end
  end

  def settlement_mathematically_possible
    return unless plaintiff_min_acceptable.present? && defendant_max_acceptable.present?

    if plaintiff_min_acceptable > defendant_max_acceptable
      errors.add(:base, "Settlement impossible: plaintiff minimum (#{plaintiff_min_acceptable}) exceeds defendant maximum (#{defendant_max_acceptable})")
    end
  end

  # Class methods for creating simulations with defaults
  def self.build_with_defaults(case_record)
    service = SimulationDefaultsService.new(case_record)
    service.build_simulation_with_defaults
  end

  def self.create_with_defaults(case_record:)
    service = SimulationDefaultsService.new(case_record)
    simulation = service.build_simulation_with_defaults
    simulation.save!
    simulation
  end

  # Instance method for randomizing financial parameters
  def randomize_financial_parameters!
    service = SimulationDefaultsService.new(self.case)
    randomized = service.randomized_financial_parameters

    self.plaintiff_min_acceptable = randomized[:plaintiff_min_acceptable]
    self.plaintiff_ideal = randomized[:plaintiff_ideal]
    self.defendant_max_acceptable = randomized[:defendant_max_acceptable]
    self.defendant_ideal = randomized[:defendant_ideal]
  end

  private_class_method :build_with_defaults, :create_with_defaults

  private

  def create_default_teams
    # Create plaintiff team
    teams.create!(
      name: "Plaintiff Team",
      description: "Default team for plaintiff side",
      role: :plaintiff,
      max_members: 10,
      owner: self.case.created_by
    )

    # Create defendant team
    teams.create!(
      name: "Defendant Team",
      description: "Default team for defendant side",
      role: :defendant,
      max_members: 10,
      owner: self.case.created_by
    )
  end
end
