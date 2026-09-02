# frozen_string_literal: true

# One entry in a Case Version's ordered in-fiction calendar. This is what lets
# an Instructor preview the schedule before Day 1 and what a Simulation's Days
# are laid out from.
class CaseCalendarDay < ApplicationRecord
  retention :authored

  belongs_to :case_version, inverse_of: :calendar_days

  validates :ordinal, numericality: {only_integer: true, greater_than_or_equal_to: 1}
  validates :in_fiction_date, presence: true
end
