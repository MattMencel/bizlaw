# frozen_string_literal: true

# An authored document waiting behind the Action that discovers it. Everything
# in the Case File is one of these.
#
# Some also carry an **Exhibit** — not a separate kind of object but a property,
# so preparation yields one thing rather than two. The property is a target, a
# sign, a shift as a fraction of the target Client's bound, and the Terms it
# bears on. It is whole or absent, by CHECK.
#
# Whether an Exhibit is favorable is not authored: it is read off who found it.
# An Exhibit targeting the opposing Client is favorable and is held to be
# played; one targeting the finder's own Client is unfavorable, is not playable
# at all, and lands the moment it is discovered. Deposing a witness who hurts
# you still teaches you something worth knowing.
class CaseDocument < ApplicationRecord
  retention :authored

  # Provenance's authored three, with the one-Side hands named by the role that
  # holds them so a hand can be compared against an Exhibit's target directly.
  # The fourth, `served`, is never authored — it is what happens when the other
  # Side plays an Exhibit, and it lives on the Case File row rather than here.
  BOTH_SIDES = "both_sides"
  DISCOVERABLE = "discoverable"
  PROVENANCES = [BOTH_SIDES, *Side::ROLES, DISCOVERABLE].freeze

  belongs_to :case_version, inverse_of: :documents
  # Absent on a document in hand at the open, which waits behind nothing. The
  # xor underneath is what keeps *doors visible, contents hidden* checkable now
  # that the NOT NULL no longer says it.
  belongs_to :case_action, inverse_of: :documents, optional: true
  has_many :document_terms,
    class_name: "CaseDocumentTerm",
    inverse_of: :case_document,
    dependent: :destroy
  # The Terms the Exhibit bears on. Empty on a document carrying none.
  has_many :bears_on_terms, through: :document_terms, source: :case_term

  before_validation { self.case_version_id ||= case_action&.case_version_id }

  validates :identifier, presence: true, uniqueness: {scope: :case_version_id}
  validates :title, :body, presence: true
  validates :provenance, inclusion: {in: PROVENANCES}
  validates :exhibit_target_role, inclusion: {in: Side::ROLES}, allow_nil: true
  # The shift is authored positive because player-caused movement is a ratchet:
  # an Exhibit only ever moves a reservation point toward settleability. That is
  # its sign. Only an Event moves one back outward.
  validates :exhibit_shift_fraction,
    numericality: {greater_than: 0, less_than_or_equal_to: 1},
    allow_nil: true
  validate :exhibit_is_whole_or_absent
  validate :waits_behind_a_door_or_sits_in_a_hand
  validate :an_open_hand_exhibit_is_favorable

  def exhibit? = exhibit_target_role.present?

  # In a Team's hands before the first Day is played, rather than waiting behind
  # an Action to be discovered.
  def in_hand_at_the_open? = provenance != DISCOVERABLE

  # Whether this Side holds it at the open. `both_sides` is both hands, which is
  # also why such a document may carry no Exhibit: it would be unfavorable to
  # whichever Client it targeted.
  def held_at_the_open_by?(role) = provenance == BOTH_SIDES || provenance == role

  # A favorable Exhibit is held to be played at the opposing Client later; an
  # unfavorable one is not playable at all.
  def favorable_to?(side) = exhibit? && exhibit_target_role != side.role

  def unfavorable_to?(side) = exhibit? && exhibit_target_role == side.role

  private

  # The CHECK underneath says the same thing. Saying it here too turns an
  # authoring mistake into a validation error rather than a fault raised from
  # inside an insert.
  def exhibit_is_whole_or_absent
    return if exhibit_target_role.nil? == exhibit_shift_fraction.nil?

    errors.add(:base, "an Exhibit carries both a target and a shift, or neither")
  end

  # The xor. Every discoverable document sits behind some Action and nothing a
  # Team starts with can also be something it finds — which is the whole of what
  # makes *doors visible, contents hidden* a thing a spec can check.
  def waits_behind_a_door_or_sits_in_a_hand
    # A Provenance the Case did not author is the inclusion validation's to
    # report; saying the xor too would name a rule the author never reached.
    return if provenance.blank?
    return if in_hand_at_the_open? == case_action_id.nil?

    errors.add(:base, "a document waits behind an Action or sits in a hand at the open, never both")
  end

  # Ammunition a Team walks in with is a position the Case authored and Par is
  # authored against it. An unfavorable Exhibit at the open is refused: its shift
  # would land before the first Day is played, spending the Client's bound with
  # no Docket line behind it and no beat to read it in.
  def an_open_hand_exhibit_is_favorable
    return unless in_hand_at_the_open? && exhibit?
    return if provenance != BOTH_SIDES && exhibit_target_role != provenance

    errors.add(:base, "a document in hand at the open carries no Exhibit against its own holder")
  end
end
