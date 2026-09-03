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
  class Commit
    # Raised when a Side reaches for a Day the Instructor's deadline or
    # force-close has already ended. A commitment written after the close would
    # be a record saying both Sides finished a Day that was taken from them.
    DayClosed = Class.new(StandardError)

    def self.call(...) = new(...).call

    def initialize(side:, day:, by:)
      @side = side
      @day = day
      @by = by
    end

    def call
      raise DayClosed, "Day #{day.ordinal} has already closed" if day.closed?

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
    end

    private

    attr_reader :side, :day, :by
  end
end
