# frozen_string_literal: true

class MetricsService
  class << self
    def track_request(endpoint:, version:, status:, duration:)
      StatsD.measure(
        "api.request.duration",
        duration,
        tags: {endpoint: endpoint, version: version, status: status}
      )

      # Track response status codes
      StatsD.increment(
        "api.response.status",
        tags: {endpoint: endpoint, version: version, status: status}
      )

      # Track error rates
      if status >= 500
        StatsD.increment(
          "api.errors.server",
          tags: {endpoint: endpoint, version: version, status: status}
        )
      elsif status >= 400
        StatsD.increment(
          "api.errors.client",
          tags: {endpoint: endpoint, version: version, status: status}
        )
      end
    end

    def track_throttle(endpoint:, version:, ip:)
      StatsD.increment(
        "api.request.throttled",
        tags: {endpoint: endpoint, version: version, ip: anonymize_ip(ip)}
      )
    end

    def track_rate_limit_remaining(endpoint:, version:, ip:, remaining:)
      StatsD.gauge(
        "api.rate_limit.remaining",
        remaining,
        tags: {endpoint: endpoint, version: version, ip: anonymize_ip(ip)}
      )
    end

    def track_auth_failure(reason:, version:)
      StatsD.increment(
        "api.auth.failure",
        tags: {reason: reason, version: version}
      )
    end

    def track_response_size(endpoint:, version:, size:)
      StatsD.histogram(
        "api.response.size",
        size,
        tags: {endpoint: endpoint, version: version}
      )
    end

    def track_db_metrics(endpoint:, version:, query_count:, query_duration:)
      StatsD.count(
        "api.database.queries",
        query_count,
        tags: {endpoint: endpoint, version: version}
      )

      StatsD.measure(
        "api.database.duration",
        query_duration,
        tags: {endpoint: endpoint, version: version}
      )
    end

    def track_memory_usage(endpoint:, version:, memory:)
      StatsD.gauge(
        "api.memory.usage",
        memory,
        tags: {endpoint: endpoint, version: version}
      )
    end

    def track_job_performance(job_class:, queue:, duration:, status:)
      StatsD.measure(
        "jobs.duration",
        duration,
        tags: {job: job_class, queue: queue, status: status}
      )
    end

    def track_cache_metrics(action:, key:, hit:)
      StatsD.increment(
        "cache.#{action}",
        tags: {key: key, hit: hit}
      )
    end

    def track_error_details(endpoint:, version:, status:, error_data:)
      # Track detailed error information
      StatsD.increment(
        "api.errors.details",
        tags: {
          endpoint: endpoint,
          version: version,
          status: status,
          error_type: error_classification(status)
        }
      )

      # Log error details for further analysis
      Rails.logger.error(
        "[API Error] endpoint=#{endpoint} version=#{version} status=#{status} " \
        "error_data=#{error_data.to_json}"
      )
    end

    private

    def anonymize_ip(ip)
      return "unknown" if ip.blank?

      # Anonymize the last octet for IPv4 or the last 80 bits for IPv6
      ip_addr = IPAddr.new(ip)
      if ip_addr.ipv4?
        ip_addr.mask(24).to_s
      else
        ip_addr.mask(48).to_s
      end
    rescue IPAddr::InvalidAddressError
      "invalid"
    end

    def error_classification(status)
      case status
      when 400..499 then "client_error"
      when 500..599 then "server_error"
      else "unknown"
      end
    end
  end
end
