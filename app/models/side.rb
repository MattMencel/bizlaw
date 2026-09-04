# frozen_string_literal: true

# Plaintiff or defendant — a position in the dispute, not a group of people. A
# Side belongs to one Simulation and there are exactly two, capped at one of
# each role by unique index.
class Side < ApplicationRecord
  retention :skeleton

  PLAINTIFF = "plaintiff"
  DEFENDANT = "defendant"
  ROLES = [PLAINTIFF, DEFENDANT].freeze

  belongs_to :simulation, inverse_of: :sides
  has_many :budgets, class_name: "DayBudget", inverse_of: :side, dependent: :restrict_with_error

  # The Docket, in the order it was written. Seen forward it is the Team's
  # calendar, because every row names the Day its result lands on.
  has_many :docket_entries, -> { order(:id) }, inverse_of: :side, dependent: :restrict_with_error

  # The Days this Side has declared itself finished with.
  has_many :day_commitments, inverse_of: :side, dependent: :restrict_with_error

  # The Case File: what this Team knows, filled by the Actions that have landed.
  has_many :case_file_documents, inverse_of: :side, dependent: :restrict_with_error

  # The Team's live draft, one per Day, and the Offers committed out of them.
  # They are separate tables per ADR 0002, so that every cross-Side read targets
  # one that structurally contains no live positions.
  has_many :staged_offers, inverse_of: :side, dependent: :restrict_with_error
  has_many :committed_offers, inverse_of: :side, dependent: :restrict_with_error

  # The Days an Instructor released this Team's Second on.
  has_many :second_waivers, inverse_of: :side, dependent: :restrict_with_error

  # Every movement of this Side's own Client. Both Sides draw on one bound per
  # Client — the opposing Team's favorable Exhibits and this Team's own
  # unfavorable discoveries spend the same budget — so they all land here.
  has_many :client_shifts, inverse_of: :side, dependent: :restrict_with_error

  # A Side runs on the Case Version its Simulation pinned; pinning it twice
  # would be a second source of truth.
  delegate :case_version, to: :simulation

  before_validation { self.organization_id ||= simulation&.organization_id }

  validates :role, inclusion: {in: ROLES}, uniqueness: {scope: :simulation_id}

  def budget_on(day) = budgets.find_by(day: day)

  # The Team's live draft on a Day, if it has one.
  def staged_offer_on(day) = staged_offers.find_by(day: day)

  # Whether the Instructor released the Second for this Team on this Day. A
  # waiver is granted for one Day and read for that Day alone; there is no query
  # here that could carry it into the next one.
  def second_waived_on?(day) = second_waivers.exists?(day: day)

  # The people on this Team, folded from Attribution.
  #
  # There is no roster and no Pairing yet, so the only record of who is on a
  # Team is who has acted for it: the Docket, the commitment ledger and the
  # staged Offer all name a member. That is enough for what depends on it — the
  # teammates eligible to second an Offer — and it is one method for the roster
  # to replace when it arrives.
  def members
    acted = docket_entries.pluck(:spent_by_user_id) +
      day_commitments.pluck(:committed_by_user_id) +
      staged_offers.pluck(:staged_by_user_id)

    User.where(id: acted.uniq).order(:name)
  end

  # What this Team has done and what is coming — a fold over three ledgers
  # rather than one table. See `Docket`.
  def docket(day: nil) = Docket.for(self, day: day)

  # The Client this Side represents, authored on the Case Version its Simulation
  # pinned.
  def client = case_version.clients.find_by(role: role)

  # How far this Client has already travelled, as a fraction of its bound. A
  # fold over the shift ledger and never a column: the bound saturates rather
  # than refusing, and a counter with a CHECK on it would crash on a legal play.
  def bound_consumed = client_shifts.sum(:applied_fraction)

  # What travel is left. Never negative — an exhausted bound clips the next
  # shift to nothing rather than owing it.
  def bound_remaining
    [ClientShift::WHOLE_BOUND - bound_consumed, 0].max
  end
end
