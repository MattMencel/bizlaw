# frozen_string_literal: true

# An Exhibit put in front of the other Side, spent. It names the Offer it rode,
# the Day it landed on, and the Case File row it was played from.
#
# `side` is the Team that played it. The Client that moved is the *other* Side's,
# so the shift row this one is the source of hangs off that Side and not this —
# see `Exhibits::Play`.
#
# It carries no relevance and no shift. Whether the play moved the Client is
# whether a `client_shifts` row points back at this one, folded on read like
# everything else that moves: an Exhibit whose Terms miss the Offer's is still
# spent and still served, and writes no shift row at all.
#
# It plays exactly once, by unique index on the Case File row.
class PlayedExhibit < ApplicationRecord
  retention :skeleton

  belongs_to :side, inverse_of: :played_exhibits
  belongs_to :day, inverse_of: :played_exhibits
  belongs_to :committed_offer, inverse_of: :played_exhibits
  belongs_to :case_file_document, inverse_of: :played_exhibit

  before_validation do
    self.organization_id ||= side&.organization_id || day&.organization_id
    self.simulation_id ||= side&.simulation_id || day&.simulation_id
  end
end
