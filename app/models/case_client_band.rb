# frozen_string_literal: true

# One band of what a Client says about where they stand, and the authored edge
# it begins at. The **key** is engine — there are two bands and a third earns
# nothing a second does not — while the threshold is the Case's, and is
# measured late, around four fifths of the bound.
#
# Which band a Client is in is never stored. It is folded from the shift ledger
# as of the moment the Consult was bought; see `Side#reaction_band`.
#
# This is where the band vocabulary lives. `Portraits` borrowed the names first,
# because a face was drawn before a band existed to derive it from, but a band
# is engine domain and the compositor only borrows its name.
class CaseClientBand < ApplicationRecord
  retention :authored

  # Holding out, and willing to be moved. In ascending order of the bound
  # consumed, which is the order the thresholds are authored in and the order a
  # Case is imported in.
  FIRM = "firm"
  READY = "ready"
  BANDS = [FIRM, READY].freeze

  belongs_to :case_client, inverse_of: :bands
  # The variants, in authored order. Several, so that a Client consulted on five
  # Days does not repeat itself verbatim.
  has_many :lines,
    -> { order(:id) },
    class_name: "CaseClientBandLine",
    inverse_of: :band,
    dependent: :destroy

  before_validation { self.case_version_id ||= case_client&.case_version_id }

  validates :key, inclusion: {in: BANDS}, uniqueness: {scope: :case_client_id}
  validates :threshold,
    numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: ClientShift::WHOLE_BOUND}

  # The variant this Consult hears. `speak_count` is how many times the node has
  # already been spoken, so a Client consulted twice in one band says the second
  # line and then comes back round to the first.
  #
  # `CONTEXT.md` under *Dialogue Node* wants the Simulation seed in here too.
  # There is no seed on `simulations` yet and one is not added on the Event
  # Deck's behalf; whoever builds the Deck adds it.
  def line(speak_count)
    variants = lines.to_a
    variants[speak_count % variants.size].body
  end
end
