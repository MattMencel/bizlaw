# frozen_string_literal: true

# A Side's Action Budget for one Day, in its two halves. The preparation half is
# ungated and buys everything that is not an Offer; the exchange half is an
# absolute number of points and is the whole brake on hoarding Exhibits.
#
# Neither half carries: the next Day's row is written fresh and today's
# remainder expires. The row is written when the Day opens and never
# recomputed, so a Section edit mid-Simulation reaches later Days only.
#
# `preparation_spent` and `exchange_spent` are ADR 0002's single materialized
# exception, re-folded from the Docket by a trigger rather than incremented.
class DayBudget < ApplicationRecord
  retention :skeleton

  PREPARATION = "preparation"
  EXCHANGE = "exchange"
  HALVES = [PREPARATION, EXCHANGE].freeze

  # Below two points nothing can be played at all — an Offer costs one and the
  # Exhibit riding it costs another — and the design stops discriminating.
  PLAYABLE_EXCHANGE_HALF = 2

  belongs_to :side, inverse_of: :budgets
  belongs_to :day, inverse_of: :budgets

  # Tenancy is written rather than joined for, and it is the Simulation as well
  # as the Organization: the composite key underneath refuses a row pairing a
  # Side from one run with a Day from another.
  before_validation do
    self.organization_id ||= day&.organization_id || side&.organization_id
    self.simulation_id ||= day&.simulation_id || side&.simulation_id
  end

  validates :preparation_budget,
    numericality: {only_integer: true, greater_than_or_equal_to: 0}
  # The floor the database refuses at is the floor the model refuses at, so a
  # quota below it comes back as a validation error rather than as a CHECK
  # violation raised from inside an insert.
  validates :exchange_budget,
    numericality: {only_integer: true, greater_than_or_equal_to: PLAYABLE_EXCHANGE_HALF}

  # What is left **today**, and only today. There is no cumulative unspent total
  # here or anywhere else: roughly an eighth of the Budget expires unspent by
  # design, so a running waste figure would grade a Team on a number the design
  # requires of it.
  def remaining_in(half)
    case half
    when PREPARATION then preparation_budget - preparation_spent
    when EXCHANGE then exchange_budget - exchange_spent
    else raise ArgumentError, "unknown half #{half.inspect}"
    end
  end
end
