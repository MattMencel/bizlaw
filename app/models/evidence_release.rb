# frozen_string_literal: true

class EvidenceRelease < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :simulation
  belongs_to :document
  belongs_to :requesting_team, class_name: "Team", optional: true

  # Delegated associations
  delegate :case, to: :simulation

  # Validations
  validates :release_round, presence: true,
                           numericality: { greater_than: 0 }
  validates :evidence_type, presence: true
  validates :impact_description, presence: true
  validates :scheduled_release_at, presence: true, if: :auto_release?

  validate :release_round_within_simulation_bounds
  validate :document_is_case_material
  validate :requesting_team_in_case, if: :team_requested?

  # Evidence types
  EVIDENCE_TYPES = %w[
    witness_statement
    expert_report
    company_document
    communication_record
    financial_document
    policy_document
    surveillance_footage
    additional_testimony
    settlement_history
    precedent_case
    medical_record
    performance_review
  ].freeze

  validates :evidence_type, inclusion: { in: EVIDENCE_TYPES }

  # Scopes
  scope :scheduled_for_round, ->(round) { where(release_round: round) }
  scope :pending_release, -> { where(released_at: nil) }
  scope :released, -> { where.not(released_at: nil) }
  scope :auto_releases, -> { where(auto_release: true) }
  scope :team_requests, -> { where(team_requested: true) }
  scope :ready_for_release, -> { where("scheduled_release_at <= ?", Time.current) }

  # Instance methods
  def released?
    released_at.present?
  end

  def ready_for_release?
    return false if released?
    return true if team_requested? && approved_for_release?
    return true if auto_release? && Time.current >= scheduled_release_at
    false
  end

  def release!
    return false unless ready_for_release?

    ActiveRecord::Base.transaction do
      update_document_access!
      update!(released_at: Time.current)
      create_release_event!
      true
    end
  rescue => e
    Rails.logger.error "Failed to release evidence #{id}: #{e.message}"
    false
  end

  def approved_for_release?
    team_requested? && release_conditions["approved_by"].present?
  end

  # Class methods
  def self.schedule_automatic_release(simulation, document, round, evidence_type, impact_description)
    create!(
      simulation: simulation,
      document: document,
      release_round: round,
      scheduled_release_at: simulation.start_date + (round * 7.days),
      evidence_type: evidence_type,
      impact_description: impact_description,
      auto_release: true,
      team_requested: false
    )
  end

  def self.create_team_request(simulation, document, requesting_team, evidence_type, justification)
    create!(
      simulation: simulation,
      document: document,
      requesting_team: requesting_team,
      release_round: simulation.current_round,
      evidence_type: evidence_type,
      impact_description: justification,
      auto_release: false,
      team_requested: true,
      release_conditions: {
        "request_justification" => justification,
        "requested_at" => Time.current
      }
    )
  end

  private

  def release_round_within_simulation_bounds
    return unless release_round.present? && simulation.present?

    if release_round > simulation.total_rounds
      errors.add(:release_round, "cannot exceed simulation total rounds")
    end
  end

  def document_is_case_material
    return unless document.present?

    unless document.case_material? && document.documentable == simulation.case
      errors.add(:document, "must be a case material for this simulation's case")
    end
  end

  def requesting_team_in_case
    return unless requesting_team.present? && simulation.present?

    unless requesting_team.case_teams.exists?(case: simulation.case)
      errors.add(:requesting_team, "must be assigned to this case")
    end
  end

  def update_document_access!
    if team_requested? && requesting_team
      document.team_restrictions = document.team_restrictions.merge(
        requesting_team.id.to_s => true
      )
    else
      document.access_level = "case_teams"
    end
    document.save!
  end

  def create_release_event!
    simulation.simulation_events.create!(
      event_type: :additional_evidence,
      triggered_at: Time.current,
      trigger_round: simulation.current_round,
      impact_description: impact_description,
      event_data: {
        "evidence_release_id" => id,
        "document_id" => document.id,
        "evidence_type" => evidence_type,
        "release_type" => team_requested? ? "team_request" : "automatic"
      },
      pressure_adjustment: {},
      automatic: auto_release?
    )
  end
end
