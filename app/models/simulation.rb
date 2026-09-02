# frozen_string_literal: true

# One complete run of one Case. It pins a published Case Version and arrives
# with its two Sides and its whole Day calendar already written — see
# `Simulations::Create`, which is the only path that lays them out.
class Simulation < ApplicationRecord
  retention :skeleton

  belongs_to :section, inverse_of: :simulations
  belongs_to :case_version
  has_many :sides, inverse_of: :simulation, dependent: :restrict_with_error
  has_many :days, -> { order(:ordinal) }, inverse_of: :simulation, dependent: :restrict_with_error

  # Tenancy is a composite foreign key, so the column is written rather than
  # joined for. It defaults from the Section and is never inferred past that.
  before_validation { self.organization_id ||= section&.organization_id }

  validate :case_version_is_published

  # The run's own calendar rather than the Case's, because the Section's Day
  # count is what the Days were laid out from.
  def day_count = days.size

  def plaintiff_side = sides.find_by(role: Side::PLAINTIFF)

  def defendant_side = sides.find_by(role: Side::DEFENDANT)

  private

  # The rule spans two tables, so it lives in Ruby rather than in a constraint,
  # per ADR 0002.
  def case_version_is_published
    errors.add(:case_version, "is a draft and cannot be pinned") if case_version&.draft?
  end
end
