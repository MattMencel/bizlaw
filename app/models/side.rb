# frozen_string_literal: true

# Plaintiff or defendant — a position in the dispute, not a group of people. A
# Side belongs to one Simulation and there are exactly two, capped at one of
# each role by unique index.
class Side < ApplicationRecord
  retention :skeleton

  PLAINTIFF = "plaintiff"
  DEFENDANT = "defendant"
  ROLES = [PLAINTIFF, DEFENDANT].freeze

  belongs_to :simulation, inverse_of: :sides
  has_many :budgets, class_name: "DayBudget", inverse_of: :side, dependent: :restrict_with_error

  # A Side runs on the Case Version its Simulation pinned; pinning it twice
  # would be a second source of truth.
  delegate :case_version, to: :simulation

  before_validation { self.organization_id ||= simulation&.organization_id }

  validates :role, inclusion: {in: ROLES}, uniqueness: {scope: :simulation_id}
end
