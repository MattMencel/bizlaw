# frozen_string_literal: true

# Configure cache store for rate limiting
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

class Rack::Attack
  ### Configure Cache ###

  # Block suspicious requests for '/etc/password' or wordpress specific paths.
  blocklist("block suspicious requests") do |req|
    Rack::Attack::Fail2Ban.filter("suspicious-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
      CGI.unescape(req.path).include?("/etc/password") ||
        req.path.include?("/wp-admin") ||
        req.path.include?("/wp-login")
    end
  end

  ### Throttle Spammy Clients ###

  # Throttle all requests by IP
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # Throttle OAuth attempts by IP
  throttle("oauth/ip", limit: 5, period: 20.seconds) do |req|
    if req.path.start_with?("/users/auth/") && !req.path.include?("/callback")
      req.ip
    end
  end

  # Throttle API requests by IP and endpoint
  throttle("api/ip", limit: 30, period: 10.seconds) do |req|
    if req.path.start_with?("/api/")
      "#{req.ip}:#{req.path.split("/")[2]}"
    end
  end

  ### Custom Throttle Response ###
  self.throttled_responder = lambda do |request|
    now = Time.now.utc
    match_data = request.env["rack.attack.match_data"]
    version = request.path.match(/\/api\/v(\d+)/)&.[](1) || "1"
    endpoint = request.path.split("/")[2..3]&.join("/") || "unknown"

    # Track throttling metrics
    MetricsService.track_throttle(
      endpoint: endpoint,
      version: version,
      ip: request.ip
    )

    headers = {
      "Content-Type" => "application/json",
      "X-RateLimit-Limit" => match_data[:limit].to_s,
      "X-RateLimit-Remaining" => "0",
      "X-RateLimit-Reset" => (now + (match_data[:period] - now.to_i % match_data[:period])).iso8601
    }

    [429, headers, [{error: "Rate limit exceeded. Please wait and try again later."}.to_json]]
  end

  ### Custom Blocklist Response ###
  self.blocklisted_responder = lambda do |request|
    [403, {"Content-Type" => "application/json"}, [{error: "Forbidden"}.to_json]]
  end
end

# Track successful requests and rate limit remaining
ActiveSupport::Notifications.subscribe("rack.attack") do |_name, _start, _finish, _id, payload|
  request = payload[:request]
  # Skip if request doesn't have env (e.g., during tests or edge cases)
  next unless request.respond_to?(:env) && request.env

  if request.env["rack.attack.match_type"] == :throttle
    match_data = request.env["rack.attack.match_data"]
    version = request.path.match(/\/api\/v(\d+)/)&.[](1) || "1"
    endpoint = request.path.split("/")[2..3]&.join("/") || "unknown"

    MetricsService.track_rate_limit_remaining(
      endpoint: endpoint,
      version: version,
      ip: request.ip,
      remaining: match_data[:limit] - match_data[:count]
    )
  end
end
