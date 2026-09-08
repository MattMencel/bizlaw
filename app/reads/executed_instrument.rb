# frozen_string_literal: true

# The settlement beat: the accepted Offer's own term sheet, executed. Both
# countersignature lines are filled — an Acceptance *is* a countersignature on
# the other Side's paper — and an execution stamp says when and on which Day.
#
# **Nothing is written for it.** Per ADR 0007 it is a read over
# `committed_offers`, `committed_offer_terms` and `offer_acceptances`, and
# explicitly not a `case_file_documents` row: that table answers *what do we
# know*, and an executed agreement is the outcome rather than knowledge. The
# schema says the same thing more bluntly — `case_document_id` is `NOT NULL`
# behind a composite foreign key, with `title` and `body` delegated through it.
#
# Both Sides read one, on the one shared instrument. The term sheet, the
# signatures and the stamp are identical for the two of them; only the Client's
# beat differs, because each Team's own Client speaks and the line is keyed on
# which Side accepted.
#
# It carries **no Reaction Band**. *firm* and *ready* mean willing to keep
# holding out, which is moot once the instrument is executed, and anything about
# how the deal landed is a pre-Release number that a Section's concurrent
# Simulations would carry from a settled Team to one still playing.
class ExecutedInstrument
  # The one settlement expression, authored to the occasion rather than derived
  # from a band. It is **invariant** — the same face whatever the terms, the
  # Side, or who accepted — because a Client whose face fell at a bad deal would
  # be a free Settlement Quality read arriving through the art.
  EXPRESSION = Portraits::SETTLEMENT

  # One Term as the deal fixed it. The amount is absent on the Terms that carry
  # no figure, which is most of them: a settlement including an apology includes
  # an apology.
  Term = Data.define(:key, :amount_cents) do
    def money? = !amount_cents.nil?
  end

  # One Side's line under the term sheet: the member who took the position and
  # the teammate who confirmed it. A line with no seconder is one that landed
  # under an Instructor's waiver, which is the only way it is ever empty — the
  # Instructor never Seconds on a Team's behalf.
  Countersignature = Data.define(:side_role, :signed_by, :seconded_by) do
    def under_waiver? = seconded_by.nil?
  end

  # What this Team's own Client says over it. Words and a face, and nothing the
  # engine computed about the deal.
  #
  # The face is a seed and an expression rather than a rendered portrait,
  # because a halftone screen is fixed in ink on the page: the compositor takes
  # the render size as an argument and this read has no business choosing one.
  # The surface that serves the beat composes it — see `Portraits::Compose`.
  Beat = Data.define(:client_role, :acceptance_role, :line, :expression, :portrait_seed)

  def self.for(...) = new(...)

  def initialize(side)
    @side = side
  end

  # False for the whole of a run that has not settled, which is every run until
  # its last act. There is no instrument until there is an Acceptance.
  def executed? = !acceptance.nil?

  # The shape of the deal, in the order the Case authors its vocabulary — the
  # order `CommittedOffer#offer_terms` already returns.
  def terms
    return [] unless executed?

    @terms ||= offer.offer_terms.map do |row|
      Term.new(key: row.key, amount_cents: row.amount_cents)
    end
  end

  # The Side that put the paper on the table, signing as it committed.
  def offered_by
    return nil unless executed?

    Countersignature.new(
      side_role: offer.side.role,
      signed_by: offer.staged_by,
      seconded_by: offer.seconded_by
    )
  end

  # The Side that took it. The countersignature that makes it an instrument.
  def accepted_by
    return nil unless executed?

    Countersignature.new(
      side_role: acceptance.side.role,
      signed_by: acceptance.accepted_by,
      seconded_by: acceptance.seconded_by
    )
  end

  # The execution stamp: when it was taken, and the Day it was taken on — which
  # need not be the Day the Offer was committed on, and is the last Day of the
  # run either way.
  def executed_at = acceptance&.created_at

  def executed_on = acceptance&.day

  # Took it, or had it taken — from this Team's side of the table. The one
  # dimension the act itself supplies, and what the Client's line is keyed on.
  def acceptance_role
    return nil unless executed?

    (acceptance.side_id == side.id) ? CaseClient::TOOK_IT : CaseClient::HAD_IT_TAKEN
  end

  def beat
    return nil unless executed?

    Beat.new(
      client_role: side.role,
      acceptance_role: acceptance_role,
      line: side.client.settlement_line(acceptance_role),
      expression: EXPRESSION,
      portrait_seed: side.client.portrait_seed
    )
  end

  private

  attr_reader :side

  # `defined?` rather than `||=`, which memoizes nothing on a live run and asks
  # the database again for every slot on the page.
  def acceptance
    return @acceptance if defined?(@acceptance)

    @acceptance = side.simulation.settlement
  end

  def offer = acceptance.committed_offer
end
