# frozen_string_literal: true

module Offers
  # An Instructor releases the Second for one Team for one Day.
  #
  # A Team whose other members are absent can stage an Offer it cannot commit.
  # That is not a mechanic; this is the answer to it, and it is granted rather
  # than exercised. The Instructor never Seconds on a Team's behalf, because
  # Attribution would then name someone who did not take the position — so what
  # this writes names who *granted* the waiver, and an Offer that lands under
  # one carries no seconder at all.
  #
  # The waiver is scoped to the Day it is granted on and does not persist into
  # the next.
  #
  # Granting it twice is harmless: the unique index underneath keeps the row of
  # whoever granted it first.
  #
  # It refuses a Day at both ends of the calendar, and for one reason: a waiver
  # cannot be taken back. A Day that has ended is `DayClosed`; a Day nobody has
  # reached is `DayNotOpen`, because `Day#open?` is only `closed_at IS NULL` and
  # every unplayed Day passes it — so without this, a waiver granted into the
  # future silently disarms the Second on a Day nobody has played and nothing
  # anywhere says so.
  class WaiveSecond
    # The Day ending between this seam's read of it and the insert. Reads are
    # not serialized, so the Day this call was handed still reads as open while
    # a Team's commit or a deadline closes it — which in a demo run from three
    # tabs is the ordinary case rather than a fault. Turning it back into this
    # seam's own refusal is the shape `Offers::Stage` and `Days::Command` both
    # use for the same class of race.
    RACED_CLOSE = /second_waivers_need_an_unclosed_day/

    def self.call(...) = new(...).call

    def initialize(side:, day:, by:)
      @side = side
      @day = day
      @by = by
    end

    def call
      raise DayClosed, "Day #{day.ordinal} has already closed" if day.closed?
      raise DayNotOpen, "Day #{day.ordinal} has not opened yet" unless opened?

      SecondWaiver.create_or_find_by!(side_id: side.id, day_id: day.id) do |row|
        row.granted_by_user_id = by.id
      end
    rescue ActiveRecord::StatementInvalid => e
      raise unless RACED_CLOSE.match?(e.message)

      day.reload
      raise DayClosed, "Day #{day.ordinal} has already closed"
    end

    private

    attr_reader :side, :day, :by

    # A Day is opened by its Budget rather than by a column: `Days::Open` writes
    # one for each Side as the Day before it closes, so of a Simulation's Days
    # exactly one is ever both unclosed and budgeted. It is asked of this Side,
    # which is the Side the waiver is granted to.
    def opened? = !side.budget_on(day).nil?
  end
end
