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

  belongs_to :side, inverse_of: :budgets
  belongs_to :day, inverse_of: :budgets

  before_validation { self.organization_id ||= day&.organization_id || side&.organization_id }

  validates :preparation_budget, :exchange_budget,
    numericality: {only_integer: true, greater_than_or_equal_to: 0}
end
