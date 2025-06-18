Feature: AI Response Caching System
  As a legal simulation platform
  I want to cache AI responses for similar contexts
  So that I can improve performance and reduce API costs while maintaining quality

  Background:
    Given I belong to an organization "University of Business Law"
    And I am enrolled in a course "Advanced Business Law"
    And the system has a sexual harassment case "Mitchell v. TechFlow Industries" in this course
    And the case has plaintiff team "Mitchell Legal Team" from this course
    And the case has defendant team "TechFlow Defense Team" from this course
    And both teams have been assigned to the case
    And the simulation has 6 negotiation rounds configured
    And the Google AI service is configured and enabled
    And the AI response caching system is enabled

  @ai_cache_hit
  Scenario: Cache hit for similar offer context
    Given I am a member of the "Mitchell Legal Team" (plaintiff)
    And a previous offer with similar context has been cached
    And the cached response is contextually appropriate
    When I submit a settlement demand of $275000
    And the system checks for cached AI responses
    Then a cached response should be used
    And the response should be contextually relevant
    And the cache hit should be logged for monitoring
    And the response time should be significantly improved
    And no new API costs should be incurred

  @ai_cache_miss
  Scenario: Cache miss requires new AI generation
    Given I am a member of the "TechFlow Defense Team" (defendant)
    And no similar context exists in the cache
    When I submit a counteroffer of $125000
    And the system checks for cached AI responses
    Then no cached response should be available
    And a new AI response should be generated
    And the new response should be cached for future use
    And the cache miss should be logged for monitoring
    And API costs should be incurred for the new generation

  @ai_cache_key_generation
  Scenario: Cache key generation based on context similarity
    Given multiple teams have submitted various offers
    When the system generates cache keys for different contexts
    Then cache keys should be based on contextual factors
    And similar offers should generate similar cache keys
    And different team roles should have different cache keys
    And round numbers should influence cache key generation
    And offer amounts should be grouped into ranges for caching

  @ai_cache_expiration
  Scenario: Cache expiration and cleanup
    Given the cache contains responses from previous sessions
    And some cached responses are older than the expiration time
    When the cache cleanup process runs
    Then expired responses should be removed from cache
    And fresh responses should be retained
    And cache storage should be optimized
    And cleanup activity should be logged

  @ai_cache_warming
  Scenario: Cache warming for common scenarios
    Given the system identifies common offer scenarios
    When the cache warming process runs
    And common offer amounts and contexts are identified
    Then AI responses should be pre-generated for common scenarios
    And the cache should be populated with anticipated responses
    And cache warming should respect API usage limits
    And warming activity should be logged for monitoring

  @ai_cache_invalidation
  Scenario: Cache invalidation after simulation events
    Given the cache contains responses for current simulation state
    When a simulation event triggers and adjusts acceptable ranges
    And the event impacts client expectations significantly
    Then related cached responses should be invalidated
    And new responses should reflect updated simulation state
    And cache invalidation should be selective and targeted
    And invalidation activity should be logged

  @ai_cache_performance
  Scenario: Cache performance monitoring and optimization
    Given the caching system has been active for multiple sessions
    When performance metrics are analyzed
    Then cache hit rates should meet target thresholds
    And average response times should show improvement
    And memory usage should remain within acceptable limits
    And cache effectiveness should be measured and reported

  @ai_cache_fallback
  Scenario: Cache system failure fallback
    Given the AI response caching system encounters an error
    When students submit offers requiring AI feedback
    And the cache is temporarily unavailable
    Then the system should fallback to direct AI generation
    And student experience should not be disrupted
    And cache errors should be logged for investigation
    And API functionality should continue normally

  @ai_cache_configuration
  Scenario: Cache configuration management
    Given I am an instructor with cache management permissions
    When I access the cache configuration settings
    Then I should be able to adjust cache expiration times
    And I should be able to set cache size limits
    And I should be able to enable or disable caching per simulation
    And I should be able to clear cache for specific simulations
    And configuration changes should take effect immediately

  @ai_cache_consistency
  Scenario: Cache consistency across different contexts
    Given similar offers are submitted by different teams
    When the system uses cached responses
    Then cached responses should be contextually adapted
    And team-specific language should be maintained
    And role-appropriate perspectives should be preserved
    And cache usage should not reveal cross-team information

  @ai_cache_storage_optimization
  Scenario: Cache storage optimization and limits
    Given the cache has accumulated many responses over time
    When cache storage approaches configured limits
    Then the system should implement intelligent eviction policies
    And frequently accessed responses should be prioritized
    And recent responses should be favored over older ones
    And storage optimization should maintain cache effectiveness

  @ai_cache_analytics
  Scenario: Cache analytics and reporting
    Given the caching system has operational data
    When instructors access cache analytics
    Then cache hit/miss ratios should be displayed
    And API cost savings from caching should be calculated
    And response time improvements should be shown
    And cache effectiveness metrics should be available
    And trends over time should be visualized

  @ai_cache_security
  Scenario: Cache security and data protection
    Given the cache contains AI-generated responses
    When cache data is stored and accessed
    Then cached responses should not contain sensitive information
    And cache access should be properly authenticated
    And cache data should be encrypted at rest
    And cache logs should not expose confidential details
    And data retention policies should be enforced

  @ai_cache_multi_simulation
  Scenario: Cache isolation between simulations
    Given multiple simulations are running simultaneously
    When teams submit offers in different simulations
    Then cache responses should be isolated by simulation
    And one simulation's cache should not affect another
    And cache keys should include simulation identifiers
    And cross-simulation cache pollution should be prevented

  @ai_cache_response_quality
  Scenario: Cache response quality maintenance
    Given cached responses are being reused
    When the system validates cached response quality
    Then cached responses should maintain educational value
    And cached responses should remain contextually appropriate
    And response quality should not degrade over time
    And quality metrics should be tracked for cached responses

  @ai_cache_load_testing
  Scenario: Cache performance under load
    Given multiple teams are actively submitting offers
    When the system experiences high concurrent usage
    Then cache performance should remain stable
    And cache hit rates should be maintained under load
    And response times should not degrade significantly
    And memory usage should remain within acceptable bounds