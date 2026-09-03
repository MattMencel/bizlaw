# frozen_string_literal: true

module Days
  # The one close path. A Day ends, and the next one begins — by exactly one
  # route, however it was triggered.
  #
  # Three callers reach here and there is no fourth: the second Side's commit
  # (`Days::Commit`), the deadline sweep (`Days::FireDeadlines`), and an
  # Instructor force-closing a stalled Day, which is this call itself rather
  # than a wrapper over it. A second path that "also closes the Day" is the bug
  # this shape exists to make impossible.
  #
  # ADR 0002 specifies the mechanism: `UPDATE days SET closed_at = ? WHERE id =
  # ? AND closed_at IS NULL`. Reads are not serialized, so two callers can both
  # find the Day open; only one gets an affected row, and only that one does the
  # open work — in the same transaction, so a crash between the close and the
  # next Day's quota leaves neither.
  #
  # Remaining Budget expires here, and there is no carry code to write: the next
  # Day's row is written fresh from the quota. Roughly an eighth of the Budget
  # will expire unspent. That is measured and accepted, not a bug.
  class Close
    def self.call(...) = new(...).call

    def initialize(day, at: Time.current)
      @day = day
      @at = at
    end

    # True when this caller is the one that closed the Day, false when someone
    # else got there first. A caller that lost the race has nothing to undo —
    # the winner has already done the open work.
    def call
      ActiveRecord::Base.transaction do
        # `update_all` rather than `update!`, because the predicate is the whole
        # mechanism: a load-then-save would read `closed_at` as nil in both
        # callers and write it in both.
        next false if Day.where(id: day.id, closed_at: nil)
          .update_all(closed_at: at, updated_at: at).zero?

        day.closed_at = at
        # The last Day closes and opens nothing. There is no Day past it to hand
        # a quota to, and the Simulation goes to arbitration rather than to a
        # Day 11.
        following = day.following
        Open.call(following) if following
        true
      end
    end

    private

    attr_reader :day, :at
  end
end
