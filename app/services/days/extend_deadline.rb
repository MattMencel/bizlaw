# frozen_string_literal: true

module Days
  # The Instructor moving a Day's deadline forward, so that a class that ran
  # short of time is not punished for it.
  #
  # It only ever moves forward. A backwards move would silently expire a Day a
  # Team is mid-way through, and ending a Day early is what the force-close is
  # for — the Instructor's powers are deliberately few, and two of them should
  # not be one control with a sign.
  #
  # The rule lives in the predicate of the write rather than in a read before
  # it, for the reason `Days::Close` does the same: two Instructors reading the
  # same deadline can persist in either order, and the later write would carry
  # the earlier time. It refuses a closed Day by the same predicate — a deadline
  # moved on a Day that has ended is a record of a clock that can never fire.
  class ExtendDeadline
    NotAnExtension = Class.new(StandardError)

    def self.call(day, to:)
      moved = Day.where(id: day.id, closed_at: nil)
        .where("deadline_at IS NULL OR deadline_at < ?", to)
        .update_all(deadline_at: to, updated_at: Time.current)

      raise NotAnExtension, refusal_for(day.reload, to) if moved.zero?

      day
    end

    # Read after the write refused, so the message names the state that actually
    # turned it down rather than the one this caller had in hand.
    def self.refusal_for(day, to)
      return "Day #{day.ordinal} has closed; its deadline can no longer move" if day.closed?

      "Day #{day.ordinal} already runs to #{day.deadline_at}; force-close it to end it sooner than #{to}"
    end
    private_class_method :refusal_for
  end
end
