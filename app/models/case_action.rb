# frozen_string_literal: true

# One entry on a Case's Action menu. The **kind** is engine — the engine knows
# what consulting a Client means — while the cost, the lead time and the half it
# draws on are authored per Case, because the economy is teaching material
# rather than engine constants.
#
# A lead time of zero lands the result on the Day it was bought.
class CaseAction < ApplicationRecord
  retention :authored

  CONSULT_CLIENT = "consult_client"
  REQUEST_DOCUMENTS = "request_documents"
  RESEARCH_PRECEDENT = "research_precedent"
  MANAGE_PRESS = "manage_press"
  DEPOSE_WITNESS = "depose_witness"
  RETAIN_EXPERT = "retain_expert"

  KINDS = [
    CONSULT_CLIENT, REQUEST_DOCUMENTS, RESEARCH_PRECEDENT,
    MANAGE_PRESS, DEPOSE_WITNESS, RETAIN_EXPERT
  ].freeze

  belongs_to :case_version, inverse_of: :actions

  validates :kind, inclusion: {in: KINDS}, uniqueness: {scope: :case_version_id}
  validates :cost, numericality: {only_integer: true, greater_than_or_equal_to: 1}
  validates :lead_time_days, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :half, inclusion: {in: DayBudget::HALVES}
end
