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
  # actually took it first. That answer comes before either gate below, because
  # by the time the second press arrives the run is settled and the Day this
  # call closed is closed: gating it first would tell a Team its own Acceptance
  # ended the Simulation it had just ended.
  #
  # It ends the run. The `offer_acceptances` row is written *before*
  # `Days::Close` runs, inside one transaction, so `Simulation#settled?` is
  # already true when the close decides whether to open the following Day —
  # which is how a settled run stops opening Days and handing out Budget.
  class Accept
    # The trigger underneath, and the reason two Acceptances can never both
    # persist in one run. Exactly one Day of a Simulation is open at a time —
    # `Days::Close` opens the next only as it closes this one — so a second
    # Acceptance racing the first always lands on the Day the first has just
    # closed, and this refuses it. That is where the invariant lives; the
    # `settled?` gate in `call` is only what turns it into an answer a caller
    # can render rather than a fault.
    DAY_ALREADY_CLOSED = /offer_acceptances_need_an_unclosed_day/

    def self.call(...) = new(...).call

    # What this seam would refuse right now, as the symbol a surface renders,
    # and `nil` when it would land. It exists so the control and the write are
    # one rule rather than two: the acceptance block prints its obstacle from
    # here and `call` raises from the same list, in the same order.
    #
    # An Acceptance has no `quote` to carry its reason the way a commit's does —
    # it costs nothing, which is the whole reason this seam sits beside
    # `Days::Command` rather than inside it — so this is the counterpart of
    # `WorkingDraft#may_draft?` being exactly `Offers::Stage`'s three refusals.
    # Review made that correction on #365 for the reason it applies here: an
    # affordance computed beside a seam is a second authority on the same rule,
    # and it drifts.
    def self.refusal_for(...) = new(...).refusal

    def initialize(offer:, side:, day:, by:, seconded_by: nil)
      @offer = offer
      @side = side
      @day = day
      @by = by
      @seconded_by = seconded_by
    end

    def call
      # Accepting your own Offer is not a deal, and no gate inside one Team
      # could make it one. It is a caller reaching for a control the draft
      # never offered, not a refusal a student should see — and it is asked
      # first, above the idempotent answer below, because that answer is scoped
      # to the accepting Team and this caller is not on it.
      if offer.side == side
        raise ArgumentError, "a Side cannot accept the Offer it put on the table"
      end

      taken = OfferAcceptance.find_by(committed_offer: offer, side: side)
      return taken if taken

      refuse!

      ActiveRecord::Base.transaction do
        acceptance = OfferAcceptance.create_or_find_by!(committed_offer: offer) do |row|
          row.side = side
          row.day = day
          row.accepted_by = by
          row.seconded_by = seconded_by
        end
        # The Day the deal was struck on ends with it, through the one close
        # path rather than beside it. The compare-and-set there already handles
        # racing a deadline fire, and the row above is what makes the close open
        # nothing after it.
        Days::Close.call(day)
        acceptance
      end
    rescue ActiveRecord::StatementInvalid => e
      raise unless DAY_ALREADY_CLOSED.match?(e.message)

      # The Day ended between this seam's read of it and the insert. Reads are
      # not serialized, so the Day this call was handed still reads as open;
      # reloading it and asking again turns the database's fault back into the
      # refusal a caller already knows how to render, which is the shape
      # `Days::Command` uses for the same class of race.
      day.reload
      refuse!
      raise DayClosed, "Day #{day.ordinal} has already closed"
    end

    # The three things this seam refuses, in the order it asks them. A settled
    # run first, because it is the one that outlives the others: an Acceptance
    # landing across the table closes the Day it landed on, so a caller reading
    # a stale page would otherwise be told its Day had closed when what actually
    # happened is that the matter ended.
    def refusal
      return :the_matter_has_already_settled if simulation.settled?
      return :the_day_has_closed if day.closed?
      return :the_acceptance_has_not_been_seconded unless seconded?

      nil
    end

    private

    attr_reader :offer, :side, :day, :by, :seconded_by

    # The same list as an exception apiece, because a caller that asked first
    # renders a sentence and one that did not has to be stopped. The refusal is
    # the rule and these are what it reads as to a caller that skipped the ask.
    def refuse!
      case refusal
      when :the_matter_has_already_settled
        raise Simulation::AlreadySettled, "this Simulation has already settled"
      when :the_day_has_closed
        raise DayClosed, "Day #{day.ordinal} has already closed"
      when :the_acceptance_has_not_been_seconded
        raise NotSeconded, "the Acceptance has not been seconded"
      end
    end

    def simulation = day.simulation

    # The accepting Team's own gate, measured against the member accepting
    # rather than against whoever staged the Offer across the table.
    def seconded?
      Second.satisfied?(side: side, day: day, taken_by: by, seconded_by: seconded_by)
    end
  end
end
