# frozen_string_literal: true

class AiUsageAlert < ApplicationRecord
  include HasUuid
  include HasTimestamps

  # Enums
  enum :alert_type, {
    budget_warning: "budget_warning",
    budget_exceeded: "budget_exceeded",
    rate_limit_warning: "rate_limit_warning",
    rate_limit_exceeded: "rate_limit_exceeded",
    service_error: "service_error",
    high_latency: "high_latency"
  }, prefix: :alert_type

  enum :status, {
    active: "active",
    acknowledged: "acknowledged",
    resolved: "resolved"
  }, prefix: :status

  # Validations
  validates :alert_type, presence: true
  validates :threshold_value, presence: true, numericality: true
  validates :current_value, presence: true, numericality: true
  validates :status, presence: true

  # Scopes
  scope :active_alerts, -> { where(status: :active) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(alert_type: type) }
  scope :today, -> { where(created_at: Date.current.beginning_of_day..Date.current.end_of_day) }

  def acknowledge!(user = nil)
    update!(
      status: :acknowledged,
      acknowledged_at: Time.current,
      acknowledged_by: user&.email
    )
  end

  def resolve!(user = nil)
    update!(
      status: :resolved,
      resolved_at: Time.current,
      resolved_by: user&.email
    )
  end

  def severity
    case alert_type
    when "budget_exceeded", "rate_limit_exceeded", "service_error"
      "high"
    when "budget_warning", "rate_limit_warning", "high_latency"
      "medium"
    else
      "low"
    end
  end

  def exceeded_threshold?
    current_value > threshold_value
  end

  def percentage_of_threshold
    return 0 if threshold_value.zero?
    ((current_value / threshold_value) * 100).round(2)
  end
end
