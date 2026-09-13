# frozen_string_literal: true

# What a Consult bought: the Client's own words about where they stand, the
# Reaction Band behind them, and their face. The Consult's counterpart to
# `ExecutedInstrument` — the other occasion a Client speaks, and the only two.
#
# **Nothing is written for it.** A Consult's whole write path is the one
# `docket_entries` row `Days::Command` charges it on; the band is folded from
# the shift ledger as of that row's own `created_at` and the wording is authored
# under the band it belongs to. So a memo is re-readable — read next week it
# still reads back what the Client said *then*, which is what an Action was
# charged for. A band that moves is shown at the next Consult, not the moment it
# moves.
#
# That is a guarantee about the *row*, and not a claim that a surface reaches
# it. `WorkingDraft` carries the Day's own Consults on the front of the
# instrument, and nothing reads a closed Day's words today; what survives the
# Day is the band, on the Docket line. A surface for the record would need
# nothing new here — folding as of the spend is what already makes one
# possible.
#
# It reaches this Team's own Client only. No other Party ever speaks and no
# other Party is drawn at all.
class ConsultMemo
  # Not a Consult's row. A memo over a deposition would have no band to fold and
  # no node to speak, so this is a caller mistake rather than a refusal a
  # student should ever see.
  NotAConsult = Class.new(ArgumentError)

  # The beat: words and a face, and nothing the engine computed beyond the band
  # itself. No reservation point, no size of any shift, no count of what has
  # landed — a band is qualitative, and its imprecision near the ends is what
  # stops a Team buying its way to the number.
  #
  # The face is a seed and an expression rather than a rendered portrait, for
  # the reason `ExecutedInstrument::Beat` carries the same pair: a halftone
  # screen is fixed in ink on the page, so the compositor takes the render size
  # as an argument and a read has no business choosing one.
  #
  # The expression *is* the band, by engine rule, so a Client's face cannot
  # change between two variants that mean the same thing.
  Beat = Data.define(:client_role, :band, :line, :expression, :portrait_seed)

  def self.for(...) = new(...)

  def initialize(entry)
    raise NotAConsult, "#{entry.kind.inspect} is not a Consult" unless entry.consult?

    @entry = entry
  end

  # The Day the Client was consulted on, and the instant they spoke. A Consult
  # lands the Day it is bought — there is no preparation to wait for — so there
  # is no second Day here.
  def day = entry.day

  def spoken_at = entry.created_at

  # *firm* or *ready*, as of the spend. The row's own answer, so the Docket line
  # and this memo cannot disagree about what was heard.
  def band = @band ||= entry.reaction_band

  def beat
    Beat.new(
      client_role: client.role,
      band: band,
      line: client.band_named(band).line(speak_count, seed: run_seed),
      expression: band,
      portrait_seed: client.portrait_seed
    )
  end

  private

  attr_reader :entry

  def client = entry.side.client

  # The run's own seed, which is half of what selects the variant. Drawn once
  # when the Simulation was laid out and immutable after, so this is as fixed as
  # the row it is read beside.
  def run_seed = entry.side.simulation.seed

  # How many times this **node** has already been spoken, which is half of what
  # selects the variant — the run's seed is the other half, and decides which
  # variant the count opens on.
  #
  # The node is the band, per `CONTEXT.md` under *Dialogue Node*, so a Consult
  # that read a different band advanced nothing here: a Team that consults once
  # while firm and once ready hears the *ready* node's opening line rather than
  # its second, and with two variants authored a count across bands would leave
  # one of them unreachable in a run.
  #
  # Counted over the rows written before this one rather than over a horizon in
  # time: the Docket is append-only, so the id order is the order they were
  # written, and two Consults written inside one fast Day can share a timestamp.
  #
  # A prior's band is folded rather than stored — there is no band column, per
  # ADR 0006 — so this is one fold per prior Consult, and ADR 0006's tie reaches
  # a little further than it did: a shift sharing a Consult's timestamp could
  # already misread that Consult's own band, and now it can also move what every
  # later Consult in that band counts. What removes the tie is unchanged —
  # `Cases::Import` refuses a Case authoring a document behind `consult_client`,
  # so nothing writes a shift in a Consult's own transaction. The N is what a Team has
  # bought all run, bounded by a Budget half a point at a time, and reusing
  # `DocketEntry#reaction_band` is what keeps this count and the memo agreeing
  # about what was heard rather than keeping two folds honest.
  def speak_count
    priors = entry.side.docket_entries.consults.where(id: ...entry.id)
    priors.to_a.count { |prior| prior.reaction_band == band }
  end
end
