# frozen_string_literal: true

# An Offer a Team has put on the table, at most one per Side per Day.
#
# This is the table every cross-Side read targets, and per ADR 0002 it is a
# separate table from `staged_offers` for exactly that reason: a read of it
# structurally contains no live positions, rather than depending on a caller
# remembering a predicate.
#
# Its one invariant is `CHECK (seconded_by_user_id != staged_by_user_id)`, the
# Second. `seconded_by` is null on an Offer that landed under an Instructor's
# waiver, and that is the only way it is ever null: there is no path by which an
# Instructor becomes the seconder of record.
#
# It carries its full Terms rather than a collapsed value, because an Offer is
# worth **two numbers, one per Client** — each Client values the Terms
# privately, and the two coincide only where the Offer is pure cash. Scoring is
# not built yet; this is the object those valuations will be read from.
class CommittedOffer < ApplicationRecord
  retention :skeleton, prose: [:note]

  # What an Offer costs to commit, in points off the exchange half. It is engine
  # rather than authored: the whole arithmetic of that half is one Offer plus
  # the Exhibits riding it, and a Case that priced the Offer itself would be
  # authoring that arithmetic away. What a Case does price is the Exhibit —
  # `case_versions.exhibit_price`, CHECKed against the pool so that the two stay
  # one decision.
  EXCHANGE_COST = 1

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
  # The shape of the deal as it landed, in the order the Case authors its
  # vocabulary. Copied out of the staged Offer inside the commit's transaction
  # and never revised after: a committed position is a position taken.
  has_many :offer_terms,
    -> { order(:case_term_id) },
    class_name: "CommittedOfferTerm",
    inverse_of: :committed_offer,
    dependent: :destroy
  has_many :terms, through: :offer_terms, source: :case_term
  # The other Side taking it. At most one, by unique index.
  has_one :acceptance, class_name: "OfferAcceptance", inverse_of: :committed_offer,
    dependent: :restrict_with_error

  before_validation do
    self.organization_id ||= side&.organization_id || day&.organization_id
    self.simulation_id ||= side&.simulation_id || day&.simulation_id
    self.case_version_id ||= side&.case_version&.id
  end

  def seconded? = seconded_by_user_id.present?

  # What the Offer puts on the table in money, in cents. Nil where the Offer
  # names no money Term at all, which is a Term-only Offer rather than one worth
  # nothing.
  def amount_cents = offer_terms.detect { |row| row.money? }&.amount_cents

  def accepted? = acceptance.present?
end
