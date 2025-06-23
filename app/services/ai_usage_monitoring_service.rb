# frozen_string_literal: true

class AiUsageMonitoringService
  DEFAULT_HOURLY_RATE_LIMIT = 1000
  DEFAULT_DAILY_BUDGET_LIMIT = 5.00
  BUDGET_WARNING_THRESHOLD = 0.9 # 90%
  ALERT_COOLDOWN_MINUTES = 60

  def initialize
    @redis = RedisService.new if defined?(RedisService)
  end

  def track_request(model:, cost:, response_time:, tokens_used: 0, request_type: "unknown", error_occurred: false)
    log = AiUsageLog.create!(
      model: model,
      cost: cost,
      response_time_ms: response_time,
      tokens_used: tokens_used,
      request_type: request_type,
      error_occurred: error_occurred
    )

    # Check for alerts after tracking
    check_budget_alerts
    check_rate_limit_alerts

    log
  end

  def daily_request_count(date = Date.current)
    AiUsageLog.where(created_at: date.all_day).count
  end

  def daily_cost(date = Date.current)
    AiUsageLog.where(created_at: date.all_day).sum(:cost)
  end

  def hourly_request_count(time = Time.current)
    AiUsageLog.where(created_at: 1.hour.ago(time)..time).count
  end

  def check_rate_limit
    current_count = hourly_request_count
    limit = rate_limit_per_hour

    if current_count >= limit
      {
        allowed: false,
        remaining: 0,
        retry_after: seconds_until_next_hour,
        message: "Rate limit exceeded: #{current_count}/#{limit} requests this hour"
      }
    else
      {
        allowed: true,
        remaining: limit - current_count,
        message: "Rate limit OK: #{current_count}/#{limit} requests this hour"
      }
    end
  end

  def check_budget_limit
    current_cost = daily_cost
    limit = daily_budget_limit
    percentage_used = (current_cost / limit * 100).round(2)

    result = {
      allowed: current_cost < limit,
      remaining_budget: [limit - current_cost, 0].max,
      percentage_used: percentage_used,
      daily_cost: current_cost,
      daily_limit: limit
    }

    if current_cost >= limit
      result[:exceeded] = true
      result[:message] = "Daily budget exceeded: $#{current_cost.round(3)} / $#{limit}"
    elsif percentage_used >= (BUDGET_WARNING_THRESHOLD * 100)
      result[:warning] = true
      result[:message] = "Approaching daily budget limit: #{percentage_used}% used"
    else
      result[:message] = "Budget OK: $#{current_cost.round(3)} / $#{limit} (#{percentage_used}%)"
    end

    result
  end

  def send_usage_alert(alert_data)
    # Check for recent similar alerts to prevent spam
    return if recent_alert_exists?(alert_data[:type])

    alert = AiUsageAlert.create!(
      alert_type: alert_data[:type],
      threshold_value: extract_threshold_value(alert_data),
      current_value: extract_current_value(alert_data),
      message: alert_data[:message] || build_alert_message(alert_data),
      metadata: alert_data.except(:type, :message)
    )

    # Send notification to administrators
    AdminNotificationService.send_ai_usage_alert(alert_data) if defined?(AdminNotificationService)

    alert
  end

  def queue_request(request_data)
    # Queue the request for processing
    AiRequestProcessingJob.perform_later(request_data) if defined?(AiRequestProcessingJob)

    queue_position = (defined?(AiRequestProcessingJob) ? AiRequestProcessingJob.queue_size : 0) + 1

    {
      queued: true,
      position: queue_position,
      estimated_wait: estimate_wait_time(queue_position),
      message: "Request queued at position #{queue_position}"
    }
  end

  def get_usage_analytics(days: 30)
    end_date = Date.current
    start_date = end_date - days.days

    logs = AiUsageLog.where(created_at: start_date.beginning_of_day..end_date.end_of_day)

    daily_breakdown = (start_date..end_date).map do |date|
      day_logs = logs.where(created_at: date.all_day)

      {
        date: date,
        requests: day_logs.count,
        cost: day_logs.sum(:cost),
        avg_response_time: day_logs.average(:response_time_ms)&.round(2) || 0,
        success_rate: calculate_success_rate(day_logs)
      }
    end

    {
      total_requests: logs.count,
      total_cost: logs.sum(:cost),
      avg_response_time: logs.average(:response_time_ms)&.round(2) || 0,
      success_rate: calculate_success_rate(logs),
      daily_breakdown: daily_breakdown,
      peak_hour: find_peak_hour(logs),
      peak_day: find_peak_day(daily_breakdown),
      model_distribution: logs.group(:model).count,
      request_type_distribution: logs.group(:request_type).count
    }
  end

  def disable_ai_services(reason:)
    Rails.cache.write("ai_services_disabled", true, expires_in: 1.day)
    Rails.cache.write("ai_services_disable_reason", reason, expires_in: 1.day)

    # Send notification
    AdminNotificationService.send_ai_service_disabled_alert if defined?(AdminNotificationService)

    Rails.logger.warn "AI services disabled: #{reason}"
  end

  def enable_ai_services
    Rails.cache.delete("ai_services_disabled")
    Rails.cache.delete("ai_services_disable_reason")

    Rails.logger.info "AI services re-enabled"
  end

  def ai_services_enabled?
    !Rails.cache.read("ai_services_disabled")
  end

  def rate_limit_per_hour
    ENV.fetch("AI_HOURLY_RATE_LIMIT", DEFAULT_HOURLY_RATE_LIMIT).to_i
  end

  def daily_budget_limit
    ENV.fetch("AI_DAILY_BUDGET_LIMIT", DEFAULT_DAILY_BUDGET_LIMIT).to_f
  end

  private

  def check_budget_alerts
    budget_status = check_budget_limit

    if budget_status[:exceeded]
      send_usage_alert(
        type: "budget_exceeded",
        daily_cost: budget_status[:daily_cost],
        daily_limit: budget_status[:daily_limit],
        percentage_used: budget_status[:percentage_used],
        message: budget_status[:message]
      )

      disable_ai_services(reason: "Daily budget exceeded")
    elsif budget_status[:warning]
      send_usage_alert(
        type: "budget_warning",
        daily_cost: budget_status[:daily_cost],
        daily_limit: budget_status[:daily_limit],
        percentage_used: budget_status[:percentage_used],
        message: budget_status[:message]
      )
    end
  end

  def check_rate_limit_alerts
    rate_status = check_rate_limit

    unless rate_status[:allowed]
      send_usage_alert(
        type: "rate_limit_exceeded",
        hourly_count: hourly_request_count,
        hourly_limit: rate_limit_per_hour,
        retry_after: rate_status[:retry_after],
        message: rate_status[:message]
      )
    end
  end

  def recent_alert_exists?(alert_type)
    AiUsageAlert.where(
      alert_type: alert_type,
      created_at: ALERT_COOLDOWN_MINUTES.minutes.ago..Time.current
    ).exists?
  end

  def extract_threshold_value(alert_data)
    case alert_data[:type]
    when "budget_warning", "budget_exceeded"
      alert_data[:daily_limit] || daily_budget_limit
    when "rate_limit_warning", "rate_limit_exceeded"
      alert_data[:hourly_limit] || rate_limit_per_hour
    else
      alert_data[:threshold] || 0
    end
  end

  def extract_current_value(alert_data)
    case alert_data[:type]
    when "budget_warning", "budget_exceeded"
      alert_data[:daily_cost] || daily_cost
    when "rate_limit_warning", "rate_limit_exceeded"
      alert_data[:hourly_count] || hourly_request_count
    else
      alert_data[:current_value] || 0
    end
  end

  def build_alert_message(alert_data)
    case alert_data[:type]
    when "budget_warning"
      "Daily budget at #{alert_data[:percentage_used]}% ($#{alert_data[:daily_cost]} / $#{alert_data[:daily_limit]})"
    when "budget_exceeded"
      "Daily budget exceeded: $#{alert_data[:daily_cost]} / $#{alert_data[:daily_limit]}"
    when "rate_limit_exceeded"
      "Hourly rate limit exceeded: #{alert_data[:hourly_count]} / #{alert_data[:hourly_limit]} requests"
    else
      "AI usage alert triggered"
    end
  end

  def seconds_until_next_hour
    (Time.current.end_of_hour - Time.current).to_i
  end

  def estimate_wait_time(queue_position)
    # Rough estimate: 2 seconds per request
    queue_position * 2
  end

  def calculate_success_rate(logs)
    return 100 if logs.count.zero?
    ((logs.successful.count.to_f / logs.count) * 100).round(2)
  end

  def find_peak_hour(logs)
    hourly_counts = logs.group_by_hour(:created_at).count
    peak = hourly_counts.max_by { |_, count| count }
    peak ? {hour: peak[0].hour, requests: peak[1]} : {hour: 0, requests: 0}
  end

  def find_peak_day(daily_breakdown)
    peak = daily_breakdown.max_by { |day| day[:requests] }
    peak || {date: Date.current, requests: 0}
  end
end
