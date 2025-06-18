# frozen_string_literal: true

# StatsD stub for testing
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

# Only define the constant if it doesn't exist
Object.const_set(:StatsD, StatsD) unless Object.const_defined?(:StatsD)
