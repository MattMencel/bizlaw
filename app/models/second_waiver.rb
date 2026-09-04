# frozen_string_literal: true

# An Instructor releasing the Second for one Team for one Day.
#
# It is granted rather than exercised: the Instructor never Seconds on a Team's
# behalf, because Attribution would then name someone who did not take the
# position. So this row names who granted the waiver, and nothing on it can be
# read as a Second — a committed Offer that landed under one carries no seconder
# at all.
#
# It is scoped to one Day by its key and there is no read that could find it
# from the next one.
class SecondWaiver < ApplicationRecord
  retention :skeleton

  belongs_to :side, inverse_of: :second_waivers
  belongs_to :day, inverse_of: :second_waivers
  belongs_to :granted_by,
    class_name: "User",
    foreign_key: :granted_by_user_id,
    inverse_of: :second_waivers

  before_validation do
    self.organization_id ||= side&.organization_id || day&.organization_id
    self.simulation_id ||= side&.simulation_id || day&.simulation_id
  end
end
