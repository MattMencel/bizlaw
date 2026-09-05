# frozen_string_literal: true

# One document in a Team's Case File — what this Team knows, as opposed to the
# Docket's what this Team has done.
#
# It is written when the Action that discovered it lands, and it is written at
# most once per Side per authored document: the unique index underneath is what
# makes a double Day-open harmless rather than merely improbable.
class CaseFileDocument < ApplicationRecord
  retention :skeleton

  belongs_to :side, inverse_of: :case_file_documents
  # The Day the Action landed on, which is the Day this reached the Case File.
  belongs_to :day, inverse_of: :case_file_documents
  belongs_to :case_document

  before_validation do
    self.organization_id ||= side&.organization_id || day&.organization_id
    self.simulation_id ||= side&.simulation_id || day&.simulation_id
    # Taken from the document rather than from the Simulation, so that a
    # document of some other Case is refused by the key rather than relabelled
    # as one of this run's.
    self.case_version_id ||= case_document&.case_version_id
  end

  # The play that spent this Exhibit, if it has been played. At most one, by
  # unique index: an Exhibit plays exactly once across the Simulation.
  has_one :played_exhibit, inverse_of: :case_file_document, dependent: :restrict_with_error

  delegate :title, :body, to: :case_document

  # Whether this Team was shown the document or found it. A served document
  # arrives when the other Side plays it, at the instant it is played.
  def served? = served_at.present?

  # Spent. A fold over the play ledger rather than a column here, like
  # everything else that moves.
  def played? = played_exhibit.present?

  # Service gives a Team knowledge, never ammunition, so a document that
  # arrived because the other Side played it carries no Exhibit property at
  # all — not the target, not the shift, and nothing to play back.
  def exhibit? = !served? && case_document.exhibit?

  def exhibit_shift_fraction = exhibit? ? case_document.exhibit_shift_fraction : nil

  # Whether an Offer over these Terms touches what this Exhibit bears on. A
  # document arguing for reinstatement is worth nothing attached to a cash-only
  # Offer.
  def bears_on?(case_term_ids)
    exhibit? && case_document.document_terms.pluck(:case_term_id).intersect?(case_term_ids)
  end

  # A document is visibly playable or visibly not, and which one depends on who
  # is holding it: an Exhibit pointing at the other Side's Client is held to be
  # played, and one pointing at your own is not playable at all. A spent one is
  # neither — it has already been put in front of them, and the ratchet leaves
  # nothing to do twice.
  def playable? = exhibit? && !played? && case_document.favorable_to?(side)

  def unfavorable? = exhibit? && case_document.unfavorable_to?(side)
end
