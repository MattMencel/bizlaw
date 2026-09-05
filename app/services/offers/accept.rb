# frozen_string_literal: true

module Offers
  # The other Side takes the deal. It is the move that can end the Simulation,
  # and it is gated by a Second exactly as the commit is — an Offer and an
  # Acceptance are the only two acts inside a Team that need one.
  #
  # It sits beside `Days::Command` rather than inside it for the reason staging
  # does: `Command`'s two verbs exist to confirm a spend, and an Acceptance has
  # no cost to confirm. The exchange half buys an Offer and the Exhibits riding
  # it and nothing else.
  #
  # The Day it is accepted on need not be the Day the Offer was committed on: an
  # Offer stands on the table until it is taken or the Simulation ends.
  #
  # A second press by a teammate is the ordinary case, so it is idempotent by
  # the unique index underneath — the row keeps the Attribution of whoever
  # actually took it first.
  class Accept
    def self.call(...) = new(...).call

    def initialize(offer:, side:, day:, by:, seconded_by: nil)
      @offer = offer
      @side = side
      @day = day
      @by = by
      @seconded_by = seconded_by
    end

    def call
      raise DayClosed, "Day #{day.ordinal} has already closed" if day.closed?

      # Accepting your own Offer is not a deal, and no gate inside one Team
      # could make it one. It is a caller reaching for a control the Boardroom
      # never offered, not a refusal a student should see.
      if offer.side == side
        raise ArgumentError, "a Side cannot accept the Offer it put on the table"
      end

      raise NotSeconded, "the Acceptance has not been seconded" unless seconded?

      OfferAcceptance.create_or_find_by!(committed_offer: offer) do |acceptance|
        acceptance.side = side
        acceptance.day = day
        acceptance.accepted_by = by
        acceptance.seconded_by = seconded_by
      end
    end

    private

    attr_reader :offer, :side, :day, :by, :seconded_by

    # The accepting Team's own gate, measured against the member accepting
    # rather than against whoever staged the Offer across the table.
    def seconded?
      Second.satisfied?(side: side, day: day, taken_by: by, seconded_by: seconded_by)
    end
  end
end
