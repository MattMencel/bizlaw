# frozen_string_literal: true

class CaseType < ApplicationRecord
  include HasUuid
  include SoftDeletable

  has_many :cases, dependent: :restrict_with_error
  has_many :documents, as: :documentable, dependent: :destroy

  validates :title, presence: true
  validates :description, presence: true
end
