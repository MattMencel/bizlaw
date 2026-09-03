# frozen_string_literal: true

module Days
  # The Instructor moving a Day's deadline forward, so that a class that ran
  # short of time is not punished for it.
  #
  # It only ever moves forward. A backwards move would silently expire a Day a
  # Team is mid-way through, and ending a Day early is what the force-close is
  # for — the Instructor's powers are deliberately few, and two of them should
  # not be one control with a sign.
  class ExtendDeadline
    NotAnExtension = Class.new(StandardError)

    def self.call(day, to:)
      if day.deadline_at.present? && to <= day.deadline_at
        raise NotAnExtension,
          "Day #{day.ordinal} already runs to #{day.deadline_at}; force-close it to end it sooner"
      end

      day.update!(deadline_at: to)
      day
    end
  end
end
