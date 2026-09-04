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
  class WaiveSecond
    def self.call(...) = new(...).call

    def initialize(side:, day:, by:)
      @side = side
      @day = day
      @by = by
    end

    def call
      raise DayClosed, "Day #{day.ordinal} has already closed" if day.closed?

      SecondWaiver.create_or_find_by!(side_id: side.id, day_id: day.id) do |row|
        row.granted_by_user_id = by.id
      end
    end

    private

    attr_reader :side, :day, :by
  end
end
