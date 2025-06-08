# frozen_string_literal: true

# Adds performance monitoring capabilities to controllers
module PerformanceMonitoring
  extend ActiveSupport::Concern

  included do
    around_action :measure_request_performance
    after_action :track_response_metrics
  end

  private

  def measure_request_performance
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    begin
      yield
    ensure
      duration = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000
      track_request_performance(duration)
    end
  end

  def track_request_performance(duration)
    endpoint = "#{controller_name}##{action_name}"
    version = request.path.match(/\/api\/v(\d+)/)&.[](1) || "1"

    MetricsService.track_request(
      endpoint: endpoint,
      version: version,
      status: response.status,
      duration: duration
    )
  end

  def track_response_metrics
    endpoint = "#{controller_name}##{action_name}"
    version = request.path.match(/\/api\/v(\d+)/)&.[](1) || "1"

    # Track response size for payload optimization monitoring
    if response.content_type == "application/json"
      MetricsService.track_response_size(
        endpoint: endpoint,
        version: version,
        size: response.body.bytesize
      )
    end

    # Track database metrics
    MetricsService.track_db_metrics(
      endpoint: endpoint,
      version: version,
      query_count: ActiveRecord::QueryCounter.query_count,
      query_duration: ActiveRecord::QueryCounter.query_duration
    )

    # Track memory usage
    MetricsService.track_memory_usage(
      endpoint: endpoint,
      version: version,
      memory: GetProcessMem.new.mb
    )
  end
end
