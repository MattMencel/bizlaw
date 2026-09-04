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

  belongs_to :case_version, inverse_of: :documents
  belongs_to :case_action, inverse_of: :documents
  has_many :document_terms,
    class_name: "CaseDocumentTerm",
    inverse_of: :case_document,
    dependent: :destroy
  # The Terms the Exhibit bears on. Empty on a document carrying none.
  has_many :bears_on_terms, through: :document_terms, source: :case_term

  before_validation { self.case_version_id ||= case_action&.case_version_id }

  validates :identifier, presence: true, uniqueness: {scope: :case_version_id}
  validates :title, :body, presence: true
  validates :exhibit_target_role, inclusion: {in: Side::ROLES}, allow_nil: true
  # The shift is authored positive because player-caused movement is a ratchet:
  # an Exhibit only ever moves a reservation point toward settleability. That is
  # its sign. Only an Event moves one back outward.
  validates :exhibit_shift_fraction,
    numericality: {greater_than: 0, less_than_or_equal_to: 1},
    allow_nil: true
  validate :exhibit_is_whole_or_absent

  def exhibit? = exhibit_target_role.present?

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
end
