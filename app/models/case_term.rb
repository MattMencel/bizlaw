# frozen_string_literal: true

# One entry in the vocabulary an Offer is built from and an Exhibit bears on:
# money plus the non-monetary terms this Case authors.
#
# Terms are atomic. A public apology and a private one are two Terms, never one
# Term with a setting — a Client values each Term at a single amount, which is
# what lets an Offer be worth one number to them.
class CaseTerm < ApplicationRecord
  retention :authored

  belongs_to :case_version, inverse_of: :terms
  has_many :document_terms,
    class_name: "CaseDocumentTerm",
    inverse_of: :case_term,
    dependent: :destroy

  validates :key, presence: true, uniqueness: {scope: :case_version_id}
end
