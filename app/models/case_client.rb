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

  # Which Side accepted, which is the one dimension a settlement line is keyed
  # on. A Client whose Team took the other Side's number and one whose number was
  # taken have different feelings about identical terms.
  TOOK_IT = "took_it"
  HAD_IT_TAKEN = "had_it_taken"
  ACCEPTANCE_ROLES = [TOOK_IT, HAD_IT_TAKEN].freeze

  SETTLEMENT_LINES = {
    TOOK_IT => :settlement_took_it,
    HAD_IT_TAKEN => :settlement_had_it_taken
  }.freeze

  belongs_to :case_version, inverse_of: :clients
  # What this Client says out loud about the Terms, sparse and immobile. Not the
  # private valuation the same Client puts on them.
  has_many :aspirations,
    class_name: "CaseClientAspiration",
    inverse_of: :case_client,
    dependent: :destroy

  validates :role, inclusion: {in: Side::ROLES}, uniqueness: {scope: :case_version_id}
  validates :bound_cents, numericality: {only_integer: true, greater_than: 0}
  # Authored prose, and one of the Morning Briefing's what-you-start-with
  # sections. It is an object in the dispute rather than a line about something
  # the engine computed, so it never reaches the model.
  validates :opening_statement, presence: true
  # The settlement beat's words, one line per acceptance role. Generated
  # dialogue rather than authored prose — the Client speaks about something the
  # engine computed — but it is stored and read exactly as the statement above
  # is, because the request path never reaches a model.
  validates(*SETTLEMENT_LINES.values, presence: true)
  # The whole of what a Case says about this Client's face. Opaque on purpose:
  # a named part choice does not survive the set being reskinned, and surviving
  # the reskin is the point of having a set. Uniqueness is not here — two seeds
  # colliding is two seeds composing to the same *identity*, which is a property
  # of the part set rather than of the string, so `Cases::Import` compares the
  # faces the Case's two Clients actually draw.
  validates :portrait_seed, presence: true

  # What this Client says over the executed instrument. There is no band here
  # and nothing computed from the terms: an invariant expression and one of two
  # authored lines, per ADR 0007.
  def settlement_line(acceptance_role)
    column = SETTLEMENT_LINES[acceptance_role] ||
      raise(ArgumentError, "#{acceptance_role.inspect} is not how a Side reaches a settlement")

    public_send(column)
  end
end
