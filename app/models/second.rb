# frozen_string_literal: true

# The only gate inside a Team: an Offer or an Acceptance lands only when a
# member other than the one who took the position confirms it. Nothing else in
# the game requires one — the preparation half stays ungated.
#
# The rule spans the roster, the Day and the Instructor's waivers, so per ADR
# 0002 it lives in Ruby rather than in a constraint. What the database holds is
# the half of it that fits in one: `CHECK (seconded_by_user_id !=
# staged_by_user_id)` on the committed Offer, and its mirror on the Acceptance.
#
# A waiver *substitutes* for the Second and nothing else does. It is granted
# rather than exercised — the Instructor never Seconds on a Team's behalf,
# because Attribution would then name someone who did not take the position —
# so an act that lands under one carries no seconder at all.
class Second
  def self.satisfied?(...) = new(...).satisfied?

  def initialize(side:, day:, taken_by:, seconded_by:)
    @side = side
    @day = day
    @taken_by = taken_by
    @seconded_by = seconded_by
  end

  def satisfied?
    return side.second_waived_on?(day) if seconded_by.nil?

    side.seconders_other_than(taken_by).exists?(id: seconded_by.id)
  end

  private

  attr_reader :side, :day, :taken_by, :seconded_by
end
