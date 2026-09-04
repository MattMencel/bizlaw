# frozen_string_literal: true

# The party a Team represents, and the only Party the engine holds a record for.
# Two per Case Version, one for each Side's role.
#
# What moves during a Simulation is the Client's reservation point. How far it
# may move in total is the **bound** — the one thing about a Client authored as
# money. Every shift against it is a fraction of it, so an Exhibit is worth the
# same share of a Client's travel whether the Section made that Client easy or
# hard.
#
# How much of the bound has been consumed is a fold over `client_shifts` and
# never a column here; see `Side#bound_consumed`.
class CaseClient < ApplicationRecord
  retention :authored

  belongs_to :case_version, inverse_of: :clients

  validates :role, inclusion: {in: Side::ROLES}, uniqueness: {scope: :case_version_id}
  validates :bound_cents, numericality: {only_integer: true, greater_than: 0}
end
