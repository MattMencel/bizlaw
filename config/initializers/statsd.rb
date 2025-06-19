# frozen_string_literal: true

# StatsD configuration for metrics collection
# In production, this would connect to a real StatsD server
# For development/test, we use a no-op stub

if Rails.env.production?
  # TODO: Configure actual StatsD client when ready
  # require 'statsd-ruby'
  # StatsD = Statsd.new('localhost', 8125)

  # For now, use stub in production too until StatsD is set up
  module StatsD
    def self.measure(*args, **kwargs)
      # No-op
    end

    def self.increment(*args, **kwargs)
      # No-op
    end

    def self.gauge(*args, **kwargs)
      # No-op
    end

    def self.count(*args, **kwargs)
      # No-op
    end

    def self.histogram(*args, **kwargs)
      # No-op
    end

    def self.timing(*args, **kwargs)
      # No-op
    end

    def self.set(*args, **kwargs)
      # No-op
    end
  end
else
  # Development and test environments use no-op stub
  module StatsD
    def self.measure(*args, **kwargs)
      # No-op
    end

    def self.increment(*args, **kwargs)
      # No-op
    end

    def self.gauge(*args, **kwargs)
      # No-op
    end

    def self.count(*args, **kwargs)
      # No-op
    end

    def self.histogram(*args, **kwargs)
      # No-op
    end

    def self.timing(*args, **kwargs)
      # No-op
    end

    def self.set(*args, **kwargs)
      # No-op
    end
  end
end

# Ensure the constant is defined globally
Object.const_set(:StatsD, StatsD) unless Object.const_defined?(:StatsD)
