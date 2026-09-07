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
