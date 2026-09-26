# frozen_string_literal: true

module Days
  # A Side commits its Day by declaring itself finished with it, and the second
  # Side to do so closes the Day.
  #
  # This sits beside `Days::Command` rather than inside it. `Command`'s two
  # verbs exist because a spend confirms — it quotes a cost, a half, what is
  # left today and the Day the result lands on — and a Day commit has none of
  # those. Committing an *Offer* is a spend and belongs in `Command`; it will
  # call this after its own spend lands, which is the direction the design
  # names: an Offer commit implies the Day commit, and the reverse does not
  # follow.
  #
  # The second press is a no-op rather than an error. Three students looking at
  # the same button is the ordinary case, and the unique index underneath is
  # what makes it harmless — the row keeps the Attribution and the time of
  # whoever actually declared it first.
  #
  # It is one player's call, with no Second and no waiver (#396): committing
  # locks nothing, so a teammate's wrong "we're done" costs nothing either —
  # the Side can still spend, stage and send until the Day closes.
  class Commit
    # Raised when a Side reaches for a Day the Instructor's deadline or
    # force-close has already ended. A commitment written after the close would
    # be a record saying both Sides finished a Day that was taken from them.
    DayClosed = Class.new(StandardError)

    # The trigger underneath. The closed Day is read before the transaction
    # that writes, so a close landing in that window passes the read and lands
    # here instead — the other Side committing from its own tab is the ordinary
    # case. It is turned back into the refusal above, as `Offers::Stage` does
    # with its `RACED_*`.
    RACED_CLOSE = /day_commitments_need_an_unclosed_day/

    def self.call(...) = new(...).call

    # What this seam would refuse right now, as the symbol a surface renders,
    # and nil when it would land. The Day commit block prints its obstacle from
    # here and `call` raises from the same list, so the control and the write
    # are one rule — the counterpart of `Offers::Accept.refusal_for`.
    def self.refusal_for(...) = new(...).refusal

    def initialize(side:, day:, by:)
      @side = side
      @day = day
      @by = by
    end

    def call
      refuse!

      ActiveRecord::Base.transaction do
        commitment = DayCommitment.create_or_find_by!(side: side, day: day) do |row|
          row.committed_by = by
        end
        # Counted rather than inferred from this call: the other Side may have
        # committed between the read above and this write, and the count is what
        # both callers agree on. Whichever of them finds two rows attempts the
        # close, and the compare-and-set settles it if both do.
        Close.call(day) if day.committed_by_both_sides?
        commitment
      end
    rescue ActiveRecord::StatementInvalid => e
      raise unless RACED_CLOSE.match?(e.message)

      # The Day this call was handed still reads as open; the close landed on
      # another connection. Reloading it and asking again gives the refusal a
      # caller already knows how to render.
      day.reload
      refuse!
      raise
    end

    # The two things this seam refuses, in the order it asks them. A settled run
    # first, because it outlives the other: an Acceptance closes the Day it
    # landed on, and a reader of a stale page should be told the matter ended
    # rather than that the Day did.
    def refusal
      return :the_simulation_has_settled if day.simulation.settled?
      return :the_day_has_closed if day.closed?

      nil
    end

    # Whether this commit would be the second, and so close the Day. It is what
    # the stub states first, and it tells the Team the other Side has already
    # committed — which the close would reveal a moment later anyway.
    def closes_the_day?
      commitments = day.commitments
      !commitments.exists?(side: side) && commitments.count + 1 >= day.simulation.sides.count
    end

    private

    # The same list as an exception apiece. A settled run has no Day left to
    # declare yourself finished with: the Acceptance closed the one it landed on
    # and opened nothing after it.
    def refuse!
      case refusal
      when :the_simulation_has_settled
        raise Simulation::AlreadySettled, "this Simulation has already settled"
      when :the_day_has_closed
        raise DayClosed, "Day #{day.ordinal} has already closed"
      end
    end

    attr_reader :side, :day, :by
  end
end
