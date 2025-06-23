# frozen_string_literal: true

class CaseType < ApplicationRecord
  # CaseType doesn't follow the standard pattern - it uses integer IDs and no soft deletion
  include HasTimestamps

  # Note: Cases no longer have a case_type_id foreign key - they use an enum instead
  has_many :documents, as: :documentable, dependent: :destroy

  validates :title, presence: true
  validates :description, presence: true
end
