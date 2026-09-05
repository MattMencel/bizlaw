# frozen_string_literal: true

# The other Side taking a committed Offer. It is the move that can end the
# Simulation, and it is gated by a Second exactly as the commit is — an Offer
# and an Acceptance are the only two acts inside a Team that need one.
#
# It costs nothing. The exchange half buys an Offer and the Exhibits riding it
# and nothing else, so an Acceptance writes no Docket spend row; what the Docket
# owes it is that it is *visible*, which is why it is folded in there beside the
# staging and the waiver.
#
# `day` is the Day it was accepted on, which need not be the Day the Offer was
# committed on. `seconded_by` is null only on an Acceptance that landed under an
# Instructor's waiver, the same way a committed Offer's is.
class OfferAcceptance < ApplicationRecord
  retention :skeleton

  belongs_to :side, inverse_of: :offer_acceptances
  belongs_to :day, inverse_of: :offer_acceptances
  belongs_to :committed_offer, inverse_of: :acceptance
  belongs_to :accepted_by,
    class_name: "User",
    foreign_key: :accepted_by_user_id,
    inverse_of: :offer_acceptances
  belongs_to :seconded_by,
    class_name: "User",
    foreign_key: :seconded_by_user_id,
    inverse_of: :seconded_acceptances,
    optional: true

  before_validation do
    self.organization_id ||= side&.organization_id || day&.organization_id
    self.simulation_id ||= side&.simulation_id || day&.simulation_id
  end

  def seconded? = seconded_by_user_id.present?
end
