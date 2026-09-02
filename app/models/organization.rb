# frozen_string_literal: true

# The institution a Section belongs to, and the boundary no data crosses.
class Organization < ApplicationRecord
  # The run's shape rather than authored material or student prose. The purge
  # is not built here, and whether an institution outlives the Sections under it
  # is a question for the ticket that builds it.
  retention :skeleton

  has_many :sections, inverse_of: :organization, dependent: :restrict_with_error

  validates :name, presence: true
end
