# frozen_string_literal: true

# What a Client says out loud about one Term, and the Terms Board's third track
# beside the Team's own position and the other Side's last committed Offer.
#
# It is what lets the board exist without ever showing Par: an aspiration is the
# in-fiction stand-in, and it gives nothing away because it does not move. They
# still want what they wanted, so a Client's stated demands never reveal that
# they have softened.
#
# **Not the Client's private valuation of the same Term.** That is what an Offer
# is scored by and what only a Consult's band ever hints at; this is the public
# sentence. The two are different numbers about the same Term and only one of
# them is showable.
#
# The set is **sparse**: a Term with no row here is one this Client is
# indifferent about, and its track carries the two live positions and no marker.
# Nothing requires a row per Client per Term.
class CaseClientAspiration < ApplicationRecord
  retention :authored

  belongs_to :case_client, inverse_of: :aspirations
  belongs_to :case_term

  before_validation { self.case_version_id ||= case_client&.case_version_id }

  # Nullable for the reason a staged Offer's Term amount is: a Client wanting an
  # apology wants an apology, and there is no figure to put on it.
  validates :amount_cents,
    numericality: {only_integer: true, greater_than: 0},
    allow_nil: true
  validates :case_term_id, uniqueness: {scope: :case_client_id}
  validate :only_money_carries_an_amount

  private

  # The same rule `StagedOfferTerm` and `CommittedOfferTerm` state, and for the
  # same reason: money is the one Term that carries a figure. Without it a
  # Client could aspire to 5,000 of apology, and the Terms Board would render a
  # money figure on a track whose other two slots structurally cannot hold one.
  #
  # Unlike the offer terms, money here may be wanted *without* a figure only in
  # the sense of not being wanted at all — an authored aspiration on money names
  # an amount, because an aspiration to money with no number says nothing.
  def only_money_carries_an_amount
    return if case_term.nil?

    if case_term.money? && amount_cents.nil?
      errors.add(:amount_cents, "is what a Client wanting money wants")
    elsif !case_term.money? && !amount_cents.nil?
      errors.add(:amount_cents, "belongs to money and #{case_term.key} is not money")
    end
  end
end
