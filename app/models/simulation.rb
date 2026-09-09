# frozen_string_literal: true

# One complete run of one Case. It pins a published Case Version and arrives
# with its two Sides and its whole Day calendar already written — see
# `Simulations::Create`, which is the only path that lays them out.
class Simulation < ApplicationRecord
  retention :skeleton

  # Raised when an act reaches a run an Acceptance has already ended. It is a
  # Simulation's own rule rather than any one seam's, so it is declared here and
  # raised by all of them — `Days::Commit`, `Offers::Stage` and `Offers::Accept`.
  # `Days::Command` turns it into a refusal instead, because a quote answers
  # rather than raises.
  AlreadySettled = Class.new(StandardError)

  # What makes two runs of one Case differ. A Consult's variants are chosen by
  # this and the speak count together, so two Teams on one Case do not hear
  # their Clients' lines in one fixed order; the Event Deck's draws will want it
  # too, and nothing draws from it yet.
  #
  # Written once by `Simulations::Create` and never after. Immutability is the
  # whole property: a Consult's memo is re-readable forever and reads back the
  # variant the Client actually spoke, so a seed that moved would rewrite
  # history a Docket line already claims. `attr_readonly` is the ordinary path's
  # refusal, and it also refuses `update_column` and `update_all`; the
  # `simulations_seed_is_written_once` trigger is what holds an UPDATE that
  # skips the model entirely. A row rewritten by `INSERT OR REPLACE` gets past
  # both, because SQLite implements that as a delete and an insert — nothing
  # does this, and a `BEFORE DELETE` refusal would stand in Retention's way.
  attr_readonly :seed

  belongs_to :section, inverse_of: :simulations
  belongs_to :case_version
  has_many :sides, inverse_of: :simulation, dependent: :restrict_with_error
  has_many :days, -> { order(:ordinal) }, inverse_of: :simulation, dependent: :restrict_with_error
  # Every Offer either Side has taken. Through the Sides rather than off the
  # tenancy column, because a Side is what takes one and the run is only the
  # place it happened.
  has_many :offer_acceptances, -> { order(:id) }, through: :sides

  # Tenancy is a composite foreign key, so the column is written rather than
  # joined for. It defaults from the Section and is never inferred past that.
  before_validation { self.organization_id ||= section&.organization_id }

  validates :seed, presence: true
  validate :case_version_is_published

  # The run's own calendar rather than the Case's, because the Section's Day
  # count is what the Days were laid out from.
  def day_count = days.size

  # A run ends in exactly one of two ways — a settlement, or Arbitration when
  # the Days run out — and this is the first of them. A fold over
  # `offer_acceptances` and never a column, per ADR 0002.
  #
  # Every seam that asks whether a Day is closed asks this too, so no act lands
  # into a finished run, and `Days::Close` opens no following Day once it is
  # true.
  def settled? = offer_acceptances.exists?

  # The Acceptance that ended it, and nil while the run is still live. First by
  # id: the seams refuse a second once the first has landed, so what this
  # guards against is a race rather than an ordinary sequence.
  def settlement = offer_acceptances.first

  def plaintiff_side = sides.find_by(role: Side::PLAINTIFF)

  def defendant_side = sides.find_by(role: Side::DEFENDANT)

  private

  # The rule spans two tables, so it lives in Ruby rather than in a constraint,
  # per ADR 0002.
  def case_version_is_published
    errors.add(:case_version, "is a draft and cannot be pinned") if case_version&.draft?
  end
end
