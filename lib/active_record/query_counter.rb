# frozen_string_literal: true

module ActiveRecord
  # Tracks database query metrics for performance monitoring
  module QueryCounter
    class << self
      def query_count
        Thread.current[:query_count] ||= 0
      end

      def query_duration
        Thread.current[:query_duration] ||= 0.0
      end

      def reset!
        Thread.current[:query_count] = 0
        Thread.current[:query_duration] = 0.0
      end

      def track_query(duration)
        Thread.current[:query_count] ||= 0
        Thread.current[:query_duration] ||= 0.0

        Thread.current[:query_count] += 1
        Thread.current[:query_duration] += duration
      end
    end

    ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      # Skip schema and transaction queries
      unless event.payload[:name].in?(%w[SCHEMA TRANSACTION])
        QueryCounter.track_query(event.duration)
      end
    end
  end
end
