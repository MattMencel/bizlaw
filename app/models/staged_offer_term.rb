# frozen_string_literal: true

# One Term on a staged Offer, over the Case's authored vocabulary.
#
# Terms are atomic — a public apology and a private one are two Terms, never one
# Term with a setting — so a Term appears on an Offer at most once and carries
# no settings but money's own amount.
#
# `amount_cents` belongs to the money Term and to no other. The rule needs the
# Term's key and so spans two tables, which per ADR 0002 puts it here rather
# than in a constraint; what the database holds is that an amount is never
# negative.
class StagedOfferTerm < ApplicationRecord
  retention :skeleton

  belongs_to :staged_offer, inverse_of: :offer_terms
  belongs_to :case_term, inverse_of: :staged_offer_terms

  before_validation do
    self.case_version_id ||= case_term&.case_version_id || staged_offer&.case_version_id
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
