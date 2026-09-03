# frozen_string_literal: true

# The unit of play. A Simulation's Days all exist before the first is played,
# because the Case authors an ordered calendar with in-fiction dates.
#
# Whether a Day is open is derived from `closed_at`; there is no status column.
class Day < ApplicationRecord
  retention :skeleton

  belongs_to :simulation, inverse_of: :days
  has_many :budgets, class_name: "DayBudget", inverse_of: :day, dependent: :restrict_with_error
  has_many :docket_entries, inverse_of: :day, dependent: :restrict_with_error
  # What arrives when this Day opens. Nothing materialises it yet.
  has_many :landing_docket_entries,
    class_name: "DocketEntry",
    foreign_key: :lands_on_day_id,
    inverse_of: :lands_on_day,
    dependent: :restrict_with_error

  before_validation { self.organization_id ||= simulation&.organization_id }

  validates :ordinal, numericality: {only_integer: true, greater_than_or_equal_to: 1}
  validates :in_fiction_date, presence: true

  scope :open, -> { where(closed_at: nil) }
  scope :closed, -> { where.not(closed_at: nil) }

  def open? = closed_at.nil?

  def closed? = !open?
end
