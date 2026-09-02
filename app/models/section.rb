# frozen_string_literal: true

# An Instructor's class group, and the unit everything configurable hangs off.
# One Section runs many concurrent Simulations.
class Section < ApplicationRecord
  retention :skeleton

  belongs_to :organization, inverse_of: :sections
  has_many :simulations, inverse_of: :section, dependent: :restrict_with_error

  validates :name, presence: true
end
