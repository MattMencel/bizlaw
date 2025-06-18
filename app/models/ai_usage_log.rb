# frozen_string_literal: true

class AiUsageLog < ApplicationRecord
  include HasUuid
  include HasTimestamps

  # Validations
  validates :model, presence: true
  validates :cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :response_time_ms, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :request_type, presence: true

  # Scopes
  scope :today, -> { where(created_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :last_hour, -> { where(created_at: 1.hour.ago..Time.current) }
  scope :last_n_days, ->(days) { where(created_at: days.days.ago..Time.current) }
  scope :by_model, ->(model) { where(model: model) }
  scope :by_request_type, ->(type) { where(request_type: type) }
  scope :successful, -> { where(error_occurred: false) }
  scope :failed, -> { where(error_occurred: true) }
  scope :recent, -> { order(created_at: :desc) }

  def self.daily_stats(date = Date.current)
    logs = where(created_at: date.beginning_of_day..date.end_of_day)

    {
      total_requests: logs.count,
      total_cost: logs.sum(:cost),
      avg_response_time: logs.average(:response_time_ms)&.round(2) || 0,
      total_tokens: logs.sum(:tokens_used),
      success_rate: calculate_success_rate(logs),
      by_model: logs.group(:model).count,
      by_request_type: logs.group(:request_type).count
    }
  end

  def self.calculate_success_rate(logs)
    return 100 if logs.count.zero?
    ((logs.successful.count.to_f / logs.count) * 100).round(2)
  end

  def self.hourly_breakdown(date = Date.current)
    logs = where(created_at: date.beginning_of_day..date.end_of_day)

    (0..23).map do |hour|
      hour_logs = logs.where(created_at: date.beginning_of_day + hour.hours..date.beginning_of_day + (hour + 1).hours)

      {
        hour: hour,
        requests: hour_logs.count,
        cost: hour_logs.sum(:cost),
        avg_response_time: hour_logs.average(:response_time_ms)&.round(2) || 0
      }
    end
  end

  def successful?
    !error_occurred
  end

  def failed?
    error_occurred
  end
end
