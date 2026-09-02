# frozen_string_literal: true

# The authored dispute a Simulation runs on. One Case backs many concurrent
# Simulations, in every Organization licensed to run it, so a Case belongs to
# no Organization.
class Case < ApplicationRecord
  retention :authored

  has_many :versions, class_name: "CaseVersion", inverse_of: :case, dependent: :restrict_with_error

  validates :identifier, presence: true, uniqueness: true
  validates :name, :licence, presence: true
end
