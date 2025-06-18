# frozen_string_literal: true

class AiCacheManagementJob < ApplicationJob
  queue_as :ai_cache

  def perform(action, simulation_id = nil, options = {})
    case action.to_sym
    when :cleanup
      perform_cleanup(simulation_id)
    when :warm_cache
      perform_cache_warming(simulation_id, options)
    when :invalidate_for_event
      perform_event_invalidation(simulation_id, options[:event_type])
    when :generate_statistics
      generate_cache_statistics(simulation_id)
    else
      Rails.logger.warn "Unknown AI cache management action: #{action}"
    end
  end

  private

  def perform_cleanup(simulation_id = nil)
    Rails.logger.info "Starting AI cache cleanup#{simulation_id ? " for simulation #{simulation_id}" : ""}"

    if simulation_id
      simulation = Simulation.find_by(id: simulation_id)
      return unless simulation

      cache_service = AiResponseCacheService.new(simulation)
      cleaned_count = cache_service.cleanup_expired_entries

      Rails.logger.info "Cleaned #{cleaned_count} cache entries for simulation #{simulation_id}"
    else
      # Global cleanup
      total_cleaned = 0

      Simulation.includes(:case).find_each do |simulation|
        cache_service = AiResponseCacheService.new(simulation)
        cleaned_count = cache_service.cleanup_expired_entries
        total_cleaned += cleaned_count
      end

      Rails.logger.info "Global cache cleanup completed: #{total_cleaned} entries cleaned"
    end
  rescue StandardError => e
    Rails.logger.error "AI cache cleanup failed: #{e.message}"
    raise e
  end

  def perform_cache_warming(simulation_id, options = {})
    simulation = Simulation.find_by(id: simulation_id)
    return unless simulation

    Rails.logger.info "Starting cache warming for simulation #{simulation_id}"

    cache_service = AiResponseCacheService.new(simulation)
    warmed_count = cache_service.warm_cache_for_common_scenarios

    Rails.logger.info "Cache warming completed for simulation #{simulation_id}: #{warmed_count} responses generated"

    # Schedule next warming if enabled
    if options[:recurring] && Rails.application.config.ai_cache_warming_enabled
      self.class.set(wait: 24.hours).perform_later(:warm_cache, simulation_id, options)
    end
  rescue StandardError => e
    Rails.logger.error "Cache warming failed for simulation #{simulation_id}: #{e.message}"
    raise e
  end

  def perform_event_invalidation(simulation_id, event_type)
    simulation = Simulation.find_by(id: simulation_id)
    return unless simulation

    Rails.logger.info "Invalidating cache for simulation #{simulation_id} after #{event_type} event"

    cache_service = AiResponseCacheService.new(simulation)
    invalidated_count = cache_service.invalidate_cache_for_event(event_type)

    Rails.logger.info "Cache invalidation completed: #{invalidated_count} entries invalidated"
  rescue StandardError => e
    Rails.logger.error "Cache invalidation failed for simulation #{simulation_id}: #{e.message}"
    raise e
  end

  def generate_cache_statistics(simulation_id = nil)
    if simulation_id
      simulation = Simulation.find_by(id: simulation_id)
      return unless simulation

      cache_service = AiResponseCacheService.new(simulation)
      stats = cache_service.cache_statistics

      Rails.logger.info "Cache statistics for simulation #{simulation_id}: #{stats}"
      stats
    else
      # Global statistics
      global_stats = {
        total_simulations: 0,
        total_hits: 0,
        total_misses: 0,
        average_hit_rate: 0.0,
        estimated_total_size: 0
      }

      Simulation.includes(:case).find_each do |simulation|
        cache_service = AiResponseCacheService.new(simulation)
        stats = cache_service.cache_statistics

        global_stats[:total_simulations] += 1
        global_stats[:total_hits] += stats[:hit_count]
        global_stats[:total_misses] += stats[:miss_count]
        global_stats[:estimated_total_size] += stats[:estimated_size]
      end

      total_requests = global_stats[:total_hits] + global_stats[:total_misses]
      global_stats[:average_hit_rate] = if total_requests > 0
                                         (global_stats[:total_hits].to_f / total_requests * 100).round(2)
      else
                                         0.0
      end

      Rails.logger.info "Global cache statistics: #{global_stats}"
      global_stats
    end
  rescue StandardError => e
    Rails.logger.error "Cache statistics generation failed: #{e.message}"
    raise e
  end
end
