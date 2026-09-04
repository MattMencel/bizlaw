# frozen_string_literal: true

# An Offer a Team has put on the table, at most one per Side per Day.
#
# This is the table every cross-Side read targets, and per ADR 0002 it is a
# separate table from `staged_offers` for exactly that reason: a read of it
# structurally contains no live positions, rather than depending on a caller
# remembering a predicate.
#
# It stays empty until the commit path is built. What is here now is its shape
# and its one invariant — `CHECK (seconded_by_user_id != staged_by_user_id)`,
# the Second. `seconded_by` is null on an Offer that landed under an
# Instructor's waiver, and that is the only way it is ever null: there is no
# path by which an Instructor becomes the seconder of record.
class CommittedOffer < ApplicationRecord
  retention :skeleton, prose: [:note]

  belongs_to :side, inverse_of: :committed_offers
  belongs_to :day, inverse_of: :committed_offers
  belongs_to :staged_by,
    class_name: "User",
    foreign_key: :staged_by_user_id,
    inverse_of: :committed_offers
  belongs_to :seconded_by,
    class_name: "User",
    foreign_key: :seconded_by_user_id,
    inverse_of: :seconded_offers,
    optional: true

  before_validation do
    self.organization_id ||= side&.organization_id || day&.organization_id
    self.simulation_id ||= side&.simulation_id || day&.simulation_id
    self.case_version_id ||= side&.case_version&.id
  end

  def seconded? = seconded_by_user_id.present?
end
