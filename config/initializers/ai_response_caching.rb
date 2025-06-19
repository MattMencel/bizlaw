# frozen_string_literal: true

# AI Response Caching Configuration
Rails.application.configure do
  # Enable AI response caching in production and staging
  # Disable in development and test to ensure fresh responses during development
  config.ai_response_caching = Rails.env.production? || Rails.env.staging?

  # Cache configuration
  config.ai_cache_expiration = 2.hours
  config.ai_cache_max_size = 1000

  # Enable cache warming for common scenarios
  config.ai_cache_warming_enabled = Rails.env.production?

  # Cache cleanup schedule (would be handled by background job in production)
  config.ai_cache_cleanup_interval = 6.hours
end

# Log caching configuration on startup
Rails.logger.info "AI Response Caching: #{Rails.application.config.ai_response_caching ? "ENABLED" : "DISABLED"}"
if Rails.application.config.ai_response_caching
  Rails.logger.info "AI Cache expiration: #{Rails.application.config.ai_cache_expiration}"
  Rails.logger.info "AI Cache max size: #{Rails.application.config.ai_cache_max_size}"
end
