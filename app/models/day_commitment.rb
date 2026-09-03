# frozen_string_literal: true

# A Side declaring itself finished with a Day. Committing the Day and committing
# an Offer are different acts: an Offer commit implies this one, and the reverse
# does not follow — a Side that spent its whole Budget on preparation and made
# no Offer has still finished its Day.
#
# It carries Attribution for the same reason the Docket does. It is not a spend,
# so it is not a Docket row; it is the ledger the close counts from.
class DayCommitment < ApplicationRecord
  retention :skeleton

  belongs_to :side, inverse_of: :day_commitments
  belongs_to :day, inverse_of: :commitments
  belongs_to :committed_by,
    class_name: "User",
    foreign_key: :committed_by_user_id,
    inverse_of: :day_commitments

  before_validation do
    self.organization_id ||= side&.organization_id || day&.organization_id
    self.simulation_id ||= side&.simulation_id || day&.simulation_id
  end
end
