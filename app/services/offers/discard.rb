# frozen_string_literal: true

module Offers
  # A Team takes its draft off its own table. It costs nothing and writes no
  # Docket row, and it leaves nothing behind: a discarded Offer was never a
  # position, so there is no tombstone owed for it.
  #
  # Discarding a Day with no draft on it is a no-op rather than an error, for
  # the reason a second Day commit is: several students looking at the same
  # control is the ordinary case.
  class Discard
    def self.call(...) = new(...).call

    def initialize(side:, day:)
      @side = side
      @day = day
    end

    def call = side.staged_offer_on(day)&.destroy!

    private

    attr_reader :side, :day
  end
end
