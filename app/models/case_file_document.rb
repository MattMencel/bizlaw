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

  delegate :title, :body, :exhibit?, :exhibit_shift_fraction, to: :case_document

  # A document is visibly playable or visibly not, and which one depends on who
  # is holding it: an Exhibit pointing at the other Side's Client is held to be
  # played, and one pointing at your own is not playable at all.
  def playable? = case_document.favorable_to?(side)

  def unfavorable? = case_document.unfavorable_to?(side)
end
