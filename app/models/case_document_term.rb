# frozen_string_literal: true

# One Term an authored document's Exhibit bears on. The Exhibit moves a Client
# only where the Offer it rides touches one of these.
class CaseDocumentTerm < ApplicationRecord
  retention :authored

  belongs_to :case_document, inverse_of: :document_terms
  belongs_to :case_term, inverse_of: :document_terms

  before_validation do
    self.case_version_id ||= case_document&.case_version_id || case_term&.case_version_id
  end
end
