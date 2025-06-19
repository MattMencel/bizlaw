# frozen_string_literal: true

class AiResponseCacheService
  include ActionView::Helpers::NumberHelper

  CACHE_EXPIRATION = 2.hours.freeze
  MAX_CACHE_SIZE = 1000

  def initialize(simulation)
    @simulation = simulation
    @cache_enabled = cache_enabled?
  end

  # Generate or retrieve cached AI response for settlement offer
  def get_or_generate_response(settlement_offer, &block)
    return yield unless @cache_enabled

    cache_key = generate_cache_key(settlement_offer)

    # Try to get from cache first
    cached_response = get_cached_response(cache_key)
    if cached_response
      Rails.logger.info "AI Cache HIT for key: #{cache_key}"
      track_cache_hit
      return adapt_cached_response(cached_response, settlement_offer)
    end

    # Cache miss - generate new response
    Rails.logger.info "AI Cache MISS for key: #{cache_key}"
    track_cache_miss

    fresh_response = yield
    if fresh_response && fresh_response[:source] == "ai"
      cache_response(cache_key, fresh_response, settlement_offer)
    end

    fresh_response
  end

  # Generate or retrieve cached AI gap analysis
  def get_or_generate_gap_analysis(plaintiff_offer, defendant_offer, &block)
    return yield unless @cache_enabled

    cache_key = generate_gap_cache_key(plaintiff_offer, defendant_offer)

    cached_analysis = get_cached_response(cache_key)
    if cached_analysis
      Rails.logger.info "AI Gap Analysis Cache HIT for key: #{cache_key}"
      track_cache_hit
      return cached_analysis
    end

    Rails.logger.info "AI Gap Analysis Cache MISS for key: #{cache_key}"
    track_cache_miss

    fresh_analysis = yield
    if fresh_analysis && fresh_analysis[:source] == "ai"
      cache_response(cache_key, fresh_analysis)
    end

    fresh_analysis
  end

  # Cache warming for common scenarios
  def warm_cache_for_common_scenarios
    return unless @cache_enabled

    Rails.logger.info "Starting cache warming for simulation #{@simulation.id}"

    common_scenarios = identify_common_scenarios
    warmed_count = 0

    common_scenarios.each do |scenario|
      break if warmed_count >= 10  # Limit warming to avoid API abuse

      begin
        mock_offer = build_scenario_offer(scenario)
        cache_key = generate_cache_key(mock_offer)

        # Only warm if not already cached
        unless cache_exists?(cache_key)
          ai_service = GoogleAiService.new
          if ai_service.enabled?
            response = ai_service.generate_settlement_feedback(mock_offer)
            cache_response(cache_key, response, mock_offer)
            warmed_count += 1

            # Small delay to respect rate limits
            sleep(0.1)
          end
        end
      rescue => e
        Rails.logger.warn "Cache warming failed for scenario #{scenario}: #{e.message}"
      end
    end

    Rails.logger.info "Cache warming completed: #{warmed_count} responses pre-generated"
    warmed_count
  end

  # Invalidate cache entries after simulation events
  def invalidate_cache_for_event(event_type)
    return unless @cache_enabled

    Rails.logger.info "Invalidating cache for simulation #{@simulation.id} after #{event_type} event"

    # Pattern to match simulation-specific cache keys
    cache_pattern = "ai_response:simulation_#{@simulation.id}:*"

    invalidated_count = 0

    # In production, this would use Redis SCAN for better performance
    # For now, we'll use a simplified approach
    cache_keys = find_cache_keys_by_pattern(cache_pattern)

    cache_keys.each do |key|
      Rails.cache.delete(key)
      invalidated_count += 1
    end

    Rails.logger.info "Invalidated #{invalidated_count} cache entries"
    invalidated_count
  end

  # Clean up expired cache entries
  def cleanup_expired_entries
    return unless @cache_enabled

    Rails.logger.info "Starting cache cleanup for expired entries"

    # This would be implemented differently with Redis
    # For Rails.cache, expiration is handled automatically
    # But we can implement custom cleanup logic here

    cleanup_count = perform_custom_cleanup

    Rails.logger.info "Cache cleanup completed: #{cleanup_count} entries cleaned"
    cleanup_count
  end

  # Get cache statistics
  def cache_statistics
    {
      enabled: @cache_enabled,
      simulation_id: @simulation.id,
      hit_count: cache_hit_count,
      miss_count: cache_miss_count,
      hit_rate: calculate_hit_rate,
      estimated_size: estimated_cache_size,
      last_cleanup: last_cleanup_time
    }
  end

  # Clear all cache for simulation
  def clear_simulation_cache
    return unless @cache_enabled

    cache_pattern = "ai_response:simulation_#{@simulation.id}:*"
    cache_keys = find_cache_keys_by_pattern(cache_pattern)

    cleared_count = 0
    cache_keys.each do |key|
      Rails.cache.delete(key)
      cleared_count += 1
    end

    Rails.logger.info "Cleared #{cleared_count} cache entries for simulation #{@simulation.id}"
    cleared_count
  end

  private

  def cache_enabled?
    # Check if caching is enabled globally and for this simulation
    Rails.application.config.respond_to?(:ai_response_caching) &&
      Rails.application.config.ai_response_caching &&
      GoogleAI.enabled?
  rescue
    false
  end

  def generate_cache_key(settlement_offer)
    team_role = determine_team_role(settlement_offer.team)
    amount_range = categorize_amount(settlement_offer.amount)
    round_number = settlement_offer.negotiation_round.round_number

    # Include simulation context and event state
    event_hash = calculate_event_state_hash

    "ai_response:simulation_#{@simulation.id}:#{team_role}:#{amount_range}:round_#{round_number}:events_#{event_hash}"
  end

  def generate_gap_cache_key(plaintiff_offer, defendant_offer)
    plaintiff_range = categorize_amount(plaintiff_offer)
    defendant_range = categorize_amount(defendant_offer)
    gap_category = categorize_gap_size(plaintiff_offer - defendant_offer)

    event_hash = calculate_event_state_hash

    "ai_gap_analysis:simulation_#{@simulation.id}:p_#{plaintiff_range}:d_#{defendant_range}:gap_#{gap_category}:events_#{event_hash}"
  end

  def categorize_amount(amount)
    case amount
    when 0..99_999 then "0k-99k"
    when 100_000..149_999 then "100k-149k"
    when 150_000..199_999 then "150k-199k"
    when 200_000..249_999 then "200k-249k"
    when 250_000..299_999 then "250k-299k"
    when 300_000..349_999 then "300k-349k"
    else "350k+"
    end
  end

  def categorize_gap_size(gap)
    case gap.abs
    when 0..49_999 then "small"
    when 50_000..149_999 then "medium"
    when 150_000..299_999 then "large"
    else "very_large"
    end
  end

  def calculate_event_state_hash
    # Create a hash representing the current state of simulation events
    # This ensures cache is invalidated when events change the simulation state
    recent_events = @simulation.simulation_events
      .where("triggered_at > ?", 24.hours.ago)
      .pluck(:event_type)
      .sort

    Digest::MD5.hexdigest(recent_events.join(","))[0..7]
  end

  def determine_team_role(team)
    case_team = @simulation.case.case_teams.find_by(team: team)
    case_team&.role || "unknown"
  end

  def get_cached_response(cache_key)
    Rails.cache.read(cache_key)
  end

  def cache_response(cache_key, response, context_offer = nil)
    # Add caching metadata
    cached_data = response.dup
    cached_data[:cached_at] = Time.current.iso8601
    cached_data[:cache_key] = cache_key
    cached_data[:context] = extract_context_info(context_offer) if context_offer

    Rails.cache.write(cache_key, cached_data, expires_in: CACHE_EXPIRATION)

    Rails.logger.debug { "Cached AI response with key: #{cache_key}" }
  end

  def cache_exists?(cache_key)
    Rails.cache.exist?(cache_key)
  end

  def adapt_cached_response(cached_response, current_offer)
    # Adapt cached response to current context if needed
    adapted_response = cached_response.dup

    # Update timestamp to show when it was retrieved
    adapted_response[:retrieved_at] = Time.current.iso8601
    adapted_response[:source] = "cache"

    # Could add context adaptation here if needed
    # For example, adjusting pronouns or specific references

    adapted_response
  end

  def extract_context_info(settlement_offer)
    {
      team_role: determine_team_role(settlement_offer.team),
      amount_range: categorize_amount(settlement_offer.amount),
      round: settlement_offer.negotiation_round.round_number
    }
  end

  def identify_common_scenarios
    # Define common negotiation scenarios for cache warming
    [
      {role: "plaintiff", amount_range: "200k-249k", round: 1},
      {role: "plaintiff", amount_range: "250k-299k", round: 1},
      {role: "plaintiff", amount_range: "250k-299k", round: 2},
      {role: "defendant", amount_range: "100k-149k", round: 1},
      {role: "defendant", amount_range: "150k-199k", round: 1},
      {role: "defendant", amount_range: "150k-199k", round: 2}
    ]
  end

  def build_scenario_offer(scenario)
    # Create a mock settlement offer for cache warming
    mock_team = build_mock_team(scenario[:role])
    mock_round = build_mock_round(scenario[:round])
    estimated_amount = estimate_amount_from_range(scenario[:amount_range])

    OpenStruct.new(
      team: mock_team,
      negotiation_round: mock_round,
      amount: estimated_amount,
      justification: "Cache warming scenario for #{scenario[:role]}"
    )
  end

  def build_mock_team(role)
    OpenStruct.new(
      case_teams: [OpenStruct.new(case: @simulation.case, role: role)]
    )
  end

  def build_mock_round(round_number)
    OpenStruct.new(
      simulation: @simulation,
      round_number: round_number
    )
  end

  def estimate_amount_from_range(amount_range)
    case amount_range
    when "0k-99k" then 75_000
    when "100k-149k" then 125_000
    when "150k-199k" then 175_000
    when "200k-249k" then 225_000
    when "250k-299k" then 275_000
    when "300k-349k" then 325_000
    else 375_000
    end
  end

  def find_cache_keys_by_pattern(pattern)
    # Simplified implementation - in production would use Redis SCAN
    # For Rails.cache with memory store, we'll use a mock implementation
    []
  end

  def perform_custom_cleanup
    # Custom cleanup logic for old or stale entries
    # Returns count of cleaned entries
    0
  end

  def track_cache_hit
    Rails.cache.increment("ai_cache_hits:simulation_#{@simulation.id}", 1, expires_in: 24.hours)
  end

  def track_cache_miss
    Rails.cache.increment("ai_cache_misses:simulation_#{@simulation.id}", 1, expires_in: 24.hours)
  end

  def cache_hit_count
    Rails.cache.read("ai_cache_hits:simulation_#{@simulation.id}") || 0
  end

  def cache_miss_count
    Rails.cache.read("ai_cache_misses:simulation_#{@simulation.id}") || 0
  end

  def calculate_hit_rate
    hits = cache_hit_count
    misses = cache_miss_count
    total = hits + misses

    return 0.0 if total.zero?
    (hits.to_f / total * 100).round(2)
  end

  def estimated_cache_size
    # Estimate cache size for this simulation
    # In production, this would query Redis for actual size
    cache_hit_count + cache_miss_count
  end

  def last_cleanup_time
    Rails.cache.read("ai_cache_last_cleanup:simulation_#{@simulation.id}") || "Never"
  end
end
