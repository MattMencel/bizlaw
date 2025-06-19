# frozen_string_literal: true

class SimulationEvent < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :simulation

  # Delegated associations
  delegate :case, :plaintiff_team, :defendant_team, to: :simulation

  # Validations
  validates :event_type, presence: true
  validates :triggered_at, presence: true
  validates :impact_description, presence: true,
    length: {minimum: 10, maximum: 500}
  validates :trigger_round, presence: true,
    numericality: {greater_than: 0}
  validates :event_data, presence: true
  validates :pressure_adjustment, presence: true

  # Enums
  enum :event_type, {
    media_attention: "media_attention",
    witness_change: "witness_change",
    ipo_delay: "ipo_delay",
    court_deadline: "court_deadline",
    additional_evidence: "additional_evidence",
    expert_testimony: "expert_testimony"
  }, prefix: :event

  # Scopes
  scope :triggered, -> { where("triggered_at <= ?", Time.current) }
  scope :pending, -> { where("triggered_at > ?", Time.current) }
  scope :for_round, ->(round) { where(trigger_round: round) }
  scope :automatic_events, -> { where(automatic: true) }
  scope :manual_events, -> { where(automatic: false) }
  scope :by_trigger_time, -> { order(:triggered_at) }

  # Instance methods
  def triggered?
    triggered_at <= Time.current
  end

  def pending?
    !triggered?
  end

  def apply_pressure_adjustments!
    return false unless triggered?
    return false if pressure_adjustment.blank?

    adjustments_applied = {}

    # Apply plaintiff adjustments
    if pressure_adjustment["plaintiff_min_increase"].present?
      increase = pressure_adjustment["plaintiff_min_increase"].to_f
      new_min = simulation.plaintiff_min_acceptable + increase
      simulation.update!(plaintiff_min_acceptable: new_min)
      adjustments_applied[:plaintiff_min_increase] = increase
    end

    # Apply defendant adjustments
    if pressure_adjustment["defendant_max_increase"].present?
      increase = pressure_adjustment["defendant_max_increase"].to_f
      new_max = simulation.defendant_max_acceptable + increase
      simulation.update!(defendant_max_acceptable: new_max)
      adjustments_applied[:defendant_max_increase] = increase
    end

    # Update event data to track what was applied
    self.event_data = event_data.merge(
      "adjustments_applied" => adjustments_applied,
      "applied_at" => Time.current.iso8601
    )
    save!

    true
  end

  def notification_message
    case event_type
    when "media_attention"
      "📺 #{impact_description}"
    when "witness_change"
      "👥 #{impact_description}"
    when "ipo_delay"
      "📈 #{impact_description}"
    when "court_deadline"
      "⚖️ #{impact_description}"
    when "additional_evidence"
      "📋 #{impact_description}"
    when "expert_testimony"
      "🎓 #{impact_description}"
    else
      "📢 #{impact_description}"
    end
  end

  def pressure_impact_summary
    return "No pressure adjustments" if pressure_adjustment.blank?

    impacts = []

    if pressure_adjustment["plaintiff_min_increase"].present?
      amount = pressure_adjustment["plaintiff_min_increase"]
      impacts << "Plaintiff minimum increased by $#{number_with_delimiter(amount)}"
    end

    if pressure_adjustment["defendant_max_increase"].present?
      amount = pressure_adjustment["defendant_max_increase"]
      impacts << "Defendant maximum increased by $#{number_with_delimiter(amount)}"
    end

    impacts.any? ? impacts.join("; ") : "General pressure increase"
  end

  # Class methods
  def self.create_media_attention_event(simulation, round_number)
    create!(
      simulation: simulation,
      event_type: :media_attention,
      trigger_round: round_number,
      triggered_at: Time.current,
      impact_description: "Local news outlet reports on harassment lawsuit",
      event_data: {
        "media_outlet" => "Local Business Journal",
        "story_type" => "investigative_report",
        "public_pressure" => "moderate"
      },
      pressure_adjustment: {
        "plaintiff_min_increase" => 25000,
        "defendant_max_increase" => 50000
      },
      automatic: true
    )
  end

  def self.create_witness_change_event(simulation, round_number)
    create!(
      simulation: simulation,
      event_type: :witness_change,
      trigger_round: round_number,
      triggered_at: Time.current,
      impact_description: "Additional witness comes forward with supporting testimony",
      event_data: {
        "witness_type" => "corroborating_colleague",
        "testimony_strength" => "strong",
        "credibility" => "high"
      },
      pressure_adjustment: {
        "defendant_max_increase" => 75000
      },
      automatic: true
    )
  end

  def self.create_ipo_delay_event(simulation, round_number)
    create!(
      simulation: simulation,
      event_type: :ipo_delay,
      trigger_round: round_number,
      triggered_at: Time.current,
      impact_description: "Company announces IPO delay due to pending litigation",
      event_data: {
        "delay_duration" => "6_months",
        "investor_concern" => "high",
        "financial_impact" => "significant"
      },
      pressure_adjustment: {
        "defendant_max_increase" => 100000
      },
      automatic: true
    )
  end

  def self.create_court_deadline_event(simulation, round_number)
    create!(
      simulation: simulation,
      event_type: :court_deadline,
      trigger_round: round_number,
      triggered_at: Time.current,
      impact_description: "Judge schedules expedited trial date in 30 days",
      event_data: {
        "trial_date" => 30.days.from_now.to_date,
        "judge_tone" => "impatient",
        "discovery_cutoff" => 14.days.from_now.to_date
      },
      pressure_adjustment: {
        "plaintiff_min_increase" => 15000,
        "defendant_max_increase" => 40000
      },
      automatic: true
    )
  end

  private

  def number_with_delimiter(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
