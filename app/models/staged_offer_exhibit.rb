# frozen_string_literal: true

# One Exhibit riding a Team's live draft. Any number may ride one Offer, and it
# costs nothing until the Offer commits.
#
# It points at the Team's own Case File row rather than at the authored
# document, because that row is what says this Team holds the thing — and it is
# the row `played_exhibits` spends, so the two agree by construction.
#
# An Exhibit cannot be played alone: `staged_offer_id` is `NOT NULL`, so there
# is no row here without an Offer to ride.
class StagedOfferExhibit < ApplicationRecord
  retention :skeleton

  belongs_to :staged_offer, inverse_of: :offer_exhibits
  belongs_to :case_file_document

  before_validation do
    self.organization_id ||= staged_offer&.organization_id
    self.simulation_id ||= staged_offer&.simulation_id
  end
end
