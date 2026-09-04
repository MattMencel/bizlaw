# frozen_string_literal: true

module Offers
  # A Team takes its draft off its own table. It costs nothing and writes no
  # Docket row, and it leaves nothing behind: a discarded Offer was never a
  # position, so there is no tombstone owed for it.
  #
  # Discarding a Day with no draft on it is a no-op rather than an error, for
  # the reason a second Day commit is: several students looking at the same
  # control is the ordinary case. A Day that has already closed is not: the
  # draft on it is the Team's record of what it was holding when the Day was
  # taken from them.
  class Discard
    def self.call(...) = new(...).call

    def initialize(side:, day:)
      @side = side
      @day = day
    end

    def call
      raise DayClosed, "Day #{day.ordinal} has already closed" if day.closed?

      side.staged_offer_on(day)&.destroy!
    end

    private

    attr_reader :side, :day
  end
end
