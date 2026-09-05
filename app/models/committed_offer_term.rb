# frozen_string_literal: true

# One Term on a committed Offer, copied out of the staged Offer as it landed.
#
# It is the mirror of `StagedOfferTerm` and carries the same rule, because the
# committed Offer carries its full Terms rather than a collapsed value: an Offer
# is worth two numbers, one per Client, and these rows are what both valuations
# are read from. The two coincide only where the Offer is pure cash — money is
# the one Term worth its face to both Clients.
class CommittedOfferTerm < ApplicationRecord
  retention :skeleton

  belongs_to :committed_offer, inverse_of: :offer_terms
  belongs_to :case_term, inverse_of: :committed_offer_terms

  before_validation do
    self.case_version_id ||= case_term&.case_version_id || committed_offer&.case_version_id
  end

  validate :only_money_carries_an_amount

  delegate :key, to: :case_term

  def money? = case_term.money?

  private

  def only_money_carries_an_amount
    return if case_term.nil?

    if money? && amount_cents.nil?
      errors.add(:amount_cents, "is what an Offer of money is worth")
    elsif !money? && !amount_cents.nil?
      errors.add(:amount_cents, "belongs to money and #{key} is not money")
    end
  end
end
