# frozen_string_literal: true

# A Team's Offer before it is committed: visible to the whole Team, revisable,
# and costing nothing until it lands. One live draft per Side per Day.
#
# It is deliberately not the table any cross-Side read targets. Per ADR 0002 the
# committed Offers live in their own table so that every such read reaches one
# which structurally contains no live positions — the leak this guards is the
# opponent's current negotiating position.
#
# `staged_by` is the member who put the Offer on the table, and it does not move
# when the Offer is revised: the Second is defined against whoever staged it, so
# a revision that reassigned it would erase the one member the gate exists to
# exclude.
class StagedOffer < ApplicationRecord
  retention :skeleton, prose: [:note]

  belongs_to :side, inverse_of: :staged_offers
  belongs_to :day, inverse_of: :staged_offers
  belongs_to :staged_by,
    class_name: "User",
    foreign_key: :staged_by_user_id,
    inverse_of: :staged_offers
  # The shape of the deal, in the order the Case authors its vocabulary.
  has_many :offer_terms,
    -> { order(:case_term_id) },
    class_name: "StagedOfferTerm",
    inverse_of: :staged_offer,
    dependent: :destroy
  has_many :terms, through: :offer_terms, source: :case_term

  before_validation do
    self.organization_id ||= side&.organization_id || day&.organization_id
    self.simulation_id ||= side&.simulation_id || day&.simulation_id
    # The Version the Simulation pinned. The composite key underneath is what
    # then refuses a Term from any other Case.
    self.case_version_id ||= side&.case_version&.id
  end

  # What the Offer puts on the table in money, in cents. Nil where the Offer
  # names no money Term at all, which is a Term-only Offer rather than one worth
  # nothing.
  def amount_cents = offer_terms.detect { |row| row.money? }&.amount_cents

  # The teammates who may second this Offer. Everyone on the Team except
  # whoever staged it: the Second is the only gate inside a Team, and it is a
  # gate precisely because the member who wrote the position cannot pass it.
  #
  # A student staging an Offer holds a commit control that is present and
  # disabled, naming these people. This is the data it is rendered from.
  def eligible_seconders = side.seconders_other_than(staged_by)

  # A Team whose other members are absent stages an Offer it cannot commit.
  # That is not a mechanic — it is what the Instructor's waiver exists for.
  def secondable? = eligible_seconders.any? || side.second_waived_on?(day)
end
