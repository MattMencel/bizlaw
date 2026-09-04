# frozen_string_literal: true

# One movement of a Client's reservation point, appended to the ledger the
# Client's bound is folded from. `side` is the Side whose *own* Client moved: an
# unfavorable discovery moves the finder's, and a played Exhibit will move the
# opposing one.
#
# The bound is ADR 0002's deliberate contrast with the Action Budget. The
# Budget's ceiling refuses, so it is a CHECK; the bound's **saturates**, so a
# shift into an exhausted bound is clipped to whatever travel remains and still
# lands. A CHECK there would crash on a legal play, and an Exhibit played into
# an exhausted bound is still spent and still scores.
#
# So `applied_fraction` is computed here and nowhere else. A caller that
# supplies one has it overwritten, and `CHECK (abs(applied_fraction) <=
# abs(requested_fraction))` underneath makes a forgotten clip loud.
class ClientShift < ApplicationRecord
  retention :skeleton

  # An Exhibit the finder cannot play, landing at the moment of discovery.
  UNFAVORABLE_DISCOVERY = "unfavorable_discovery"
  SOURCE_KINDS = [UNFAVORABLE_DISCOVERY].freeze

  # A Client's whole travel, as a fraction of itself. Shifts are fractions of
  # the bound rather than money, so an Exhibit is worth the same share whether
  # the Section made that Client easy or hard.
  WHOLE_BOUND = 1

  belongs_to :side, inverse_of: :client_shifts
  belongs_to :day, inverse_of: :client_shifts

  before_validation do
    self.organization_id ||= side&.organization_id || day&.organization_id
    self.simulation_id ||= side&.simulation_id || day&.simulation_id
  end
  # Computed, never taken. This runs last so that a value handed in is
  # discarded rather than trusted.
  before_validation { self.applied_fraction = clipped_fraction }

  validates :source_kind, inclusion: {in: SOURCE_KINDS}
  # Player-caused movement is a ratchet, so a requested shift is inward. Only an
  # Event moves a reservation point back outward, and it is not built here.
  validates :requested_fraction,
    numericality: {greater_than: 0, less_than_or_equal_to: WHOLE_BOUND}

  private

  # Saturation, not refusal: what is left of the bound, or nothing once it is
  # exhausted. A clipped shift still lands, and a zero one is still a row —
  # the Team played it and it is part of the record.
  #
  # The arithmetic is written for inward travel, which is every shift this
  # ledger currently takes. An Event restores bound rather than consuming it,
  # so whoever builds the Event Deck widens this rather than reusing it.
  def clipped_fraction
    return if requested_fraction.nil? || side.nil?

    [requested_fraction, side.bound_remaining].min
  end
end
