# frozen_string_literal: true

# One entry in the vocabulary an Offer is built from and an Exhibit bears on:
# money plus the non-monetary terms this Case authors.
#
# Terms are atomic. A public apology and a private one are two Terms, never one
# Term with a setting — a Client values each Term at a single amount, which is
# what lets an Offer be worth one number to them.
class CaseTerm < ApplicationRecord
  retention :authored

  # The one Term the engine knows by name, because it is the one Term that
  # carries an amount and the one worth its face to both Clients. A Case that
  # authors no money Term simply has none on offer.
  MONEY = "money"

  belongs_to :case_version, inverse_of: :terms
  has_many :document_terms,
    class_name: "CaseDocumentTerm",
    inverse_of: :case_term,
    dependent: :destroy
  # Run data over authored data: a Term a Team has put on the table cannot be
  # edited out from under it by a re-import.
  has_many :staged_offer_terms, inverse_of: :case_term, dependent: :restrict_with_error
  has_many :committed_offer_terms, inverse_of: :case_term, dependent: :restrict_with_error

  validates :key, presence: true, uniqueness: {scope: :case_version_id}

  def money? = key == MONEY
end
