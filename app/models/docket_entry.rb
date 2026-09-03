# frozen_string_literal: true

# One row of the Team's chronological record of Actions taken: what was spent,
# which member spent it, and the Day its result lands. Answers *what have we
# done and what is coming*.
#
# It is append-only and it is the only thing that moves either of a Day
# Budget's spent counters, through the `AFTER INSERT` trigger that re-folds them
# from these rows. It carries the cost and the half it drew on rather than
# joining the authored Action for them, because the row is the ledger's own
# record of what was charged.
#
# It carries no per-member totals and no contribution scores: a shared record
# that ranks the people in it is a leaderboard, which is not what a Docket is.
class DocketEntry < ApplicationRecord
  retention :skeleton

  belongs_to :side, inverse_of: :docket_entries
  belongs_to :day, inverse_of: :docket_entries
  belongs_to :lands_on_day, class_name: "Day", inverse_of: :landing_docket_entries
  belongs_to :spent_by,
    class_name: "User",
    foreign_key: :spent_by_user_id,
    inverse_of: :docket_entries
  belongs_to :case_action

  before_validation { self.organization_id ||= side&.organization_id || day&.organization_id }

  validates :cost, numericality: {only_integer: true, greater_than_or_equal_to: 1}
  validates :half, inclusion: {in: DayBudget::HALVES}

  delegate :kind, to: :case_action
end
