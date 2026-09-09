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

  # How much of the digest an opening reads, as `Portraits::Identity::WORD`
  # does: four bytes is far more entropy than a Case authors variants, and it
  # keeps the draw a small integer.
  DRAW_WIDTH = 8

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

  # How fine an edge the column can hold, read off the column rather than
  # restated here so the two cannot drift. `Cases::Import` checks the authored
  # edges at this scale, because two edges a hair apart are one edge once
  # stored — and two bands sharing an edge is a partition with a tie in it.
  def self.threshold_scale = columns_hash.fetch("threshold").scale

  # The variant this Consult hears, chosen by the Simulation seed **and** how
  # many times this node has already been spoken, per `CONTEXT.md` under
  # *Dialogue Node*. The count walks the authored variants in order, so a Client
  # consulted twice in one band says the second line and then comes back round
  # to the first; the seed decides which of them the run opens on, so two Teams
  # on one Case do not hear their Client in one fixed order.
  #
  # The node is this band and not the Side, so the count is over the Consults
  # that read *this* band. A count across bands would spend a band's first
  # variant on a Consult that never heard that band, and with two variants
  # authored that makes a line unreachable in a run.
  def line(speak_count, seed:)
    variants = lines.to_a
    variants[(opening(seed) + speak_count) % variants.size].body
  end

  private

  # Where the run opens this node, salted with the node itself for the reason
  # `Portraits::Identity.draw` salts per group: one draw shared across nodes
  # would have a run's two Clients stepping in lockstep, which is the fixed
  # order complaint at a smaller scale. The Client's id is a salt here rather
  # than an identity — what has to differ between two runs of one Case is the
  # seed, and it does.
  #
  # A band is engine domain and `Portraits` only borrowed its names, so this
  # draws its own digest rather than calling into the compositor. Same width and
  # same reason: enough hex for the modulus to fall evenly across any variant
  # count a Case authors, and far short of what the digest hands back.
  def opening(seed)
    Digest::SHA256.hexdigest("#{seed}\0#{case_client_id}\0#{key}")[0, DRAW_WIDTH].to_i(16)
  end
end
