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
  # What this Day's open materialises into the Case Files.
  has_many :landing_docket_entries,
    class_name: "DocketEntry",
    foreign_key: :lands_on_day_id,
    inverse_of: :lands_on_day,
    dependent: :restrict_with_error
  has_many :case_file_documents, inverse_of: :day, dependent: :restrict_with_error
  has_many :client_shifts, inverse_of: :day, dependent: :restrict_with_error
  # The Exhibits played on this Day, each riding an Offer committed on it.
  has_many :played_exhibits, inverse_of: :day, dependent: :restrict_with_error
  # The ledger the close counts from: one row per Side that has declared itself
  # finished with this Day.
  has_many :commitments, class_name: "DayCommitment", inverse_of: :day,
    dependent: :restrict_with_error
  # The live drafts on this Day, the Offers committed out of them, and the
  # Seconds the Instructor released — each scoped to this Day and no further.
  has_many :staged_offers, inverse_of: :day, dependent: :restrict_with_error
  has_many :committed_offers, inverse_of: :day, dependent: :restrict_with_error
  has_many :second_waivers, inverse_of: :day, dependent: :restrict_with_error
  # The Offers taken on this Day, which need not be the Days they were committed
  # on.
  has_many :offer_acceptances, inverse_of: :day, dependent: :restrict_with_error

  before_validation { self.organization_id ||= simulation&.organization_id }

  validates :ordinal, numericality: {only_integer: true, greater_than_or_equal_to: 1}
  validates :in_fiction_date, presence: true

  scope :open, -> { where(closed_at: nil) }
  scope :closed, -> { where.not(closed_at: nil) }

  def open? = closed_at.nil?

  def closed? = !open?

  # A fold over the commitment ledger rather than a column, like everything else
  # that moves. The unique index underneath is what makes counting rows the same
  # as counting Sides.
  def committed_by_both_sides? = commitments.count >= simulation.sides.count

  # The Day the close opens. Nil on the last Day of the Simulation, which is
  # what stops the close reaching for a Day that does not exist.
  def following = simulation.days.find_by(ordinal: ordinal + 1)
end
