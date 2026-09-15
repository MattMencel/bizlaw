# frozen_string_literal: true

# The whole of a settled run as one page, the way `WorkingDraft` is the whole of
# a Day.
#
# It is the same instrument and the same two faces: the front is the executed
# agreement rather than a draft anybody may still write on, and the back still
# turns to the Case File and the Docket. What is gone is everything that was
# about a Day — the Morning Briefing, the Action slip, the Consult memo, the
# redline and the margin — because a settled run has no today. No Action can be
# bought, no position drawn, no Client asked, and there is no longer a position
# across the table from this one: there is one instrument that both Sides
# signed.
#
# **The margin goes with the redline, and that is a rule rather than tidying.**
# A settled sheet printing the figure on the line and what the Client asked for
# beside it is a Settlement Quality read arriving through the layout — the leak
# ADR 0007 spent three refusals closing, coming in past the copy rather than
# through it.
#
# It composes rather than replaces, like `WorkingDraft`: `ExecutedInstrument`
# answers what the deal was and who signed it, `CaseFile` and `Docket` answer
# the back, and this is where those become the flat, JSON-shaped thing a page is
# handed. The marks it shares with the live Day are `Typeset`'s. The one thing
# it decides alone is that the execution stamp is dated in the **fiction** — see
# `stamp`.
class ExecutedFile
  # The marks the register makes the same way on both of its fronts — a figure,
  # a Term's label, a document, a Docket line, the back of the file, the
  # Client's face at the one size it is served at. See `Typeset`.
  include Typeset

  def self.for(...) = new(...)

  def initialize(side, you:)
    @side = side
    @you = you
  end

  def to_props
    {
      letterhead: letterhead,
      terms: terms,
      signatures: signatures,
      stamp: stamp,
      beat: beat,
      back: back
    }
  end

  private

  attr_reader :side, :you

  def instrument = @instrument ||= side.executed_instrument

  def case_file = @case_file ||= CaseFile.for(side)

  def docket = @docket ||= Docket.for(side)

  # No Day, and no *of ten*. The clock has stopped, and printing an ordinal out
  # of a calendar nobody will reach again invites the reader to ask what happens
  # on the Day after — which is the dead end this page exists to not be. The Day
  # it was executed on is the stamp's, which is where that fact belongs.
  def letterhead
    {
      matter: side.case_version.case.name,
      role: side.role,
      in_fiction_date: instrument.executed_on.in_fiction_date.to_s,
      you: you.name
    }
  end

  # The deal as it was fixed, in the order the Case authors its vocabulary. One
  # column: what was agreed, and nothing it was measured against.
  def terms
    instrument.terms.map do |term|
      {
        term: term.key,
        label: label_for(term.key),
        money: term.money?,
        amount: term.money? ? money(term.amount_cents) : nil
      }
    end
  end

  # Two parties, two hands each. The Side that drew the instrument signed it by
  # committing; the Side that took it signed by accepting — an Acceptance *is* a
  # countersignature, which is why both blocks have the same shape.
  #
  # `waived` is how the record says a line was never signed rather than leaving
  # it blank, exactly as the working block does: an instrument that landed under
  # an Instructor's waiver carries no seconder at all, and a blank second line
  # would read as one nobody got round to.
  def signatures
    [instrument.offered_by, instrument.accepted_by].map do |line|
      {
        role: line.side_role,
        signed_by: line.signed_by.name,
        seconded_by: line.seconded_by&.name,
        waived: line.under_waiver?
      }
    end
  end

  # **Dated in the fiction.** Every other date on the instrument is the Case's
  # calendar, and `offer_acceptances.created_at` is the afternoon the demo
  # happened to run — a wall clock on the one document that records what the two
  # Teams agreed. The row keeps it; this page does not read it.
  def stamp
    {
      day: instrument.executed_on.ordinal,
      in_fiction_date: instrument.executed_on.in_fiction_date.to_s
    }
  end

  # This Team's own Client, on the one occasion that is not a Consult.
  #
  # **No band.** ADR 0007 is explicit and the reason is not consistency: *firm*
  # and *ready* mean willing to keep holding out, which is moot the instant the
  # instrument is executed, and a band here would be a free read on how the deal
  # landed. The expression is authored to the occasion instead, invariant to the
  # terms, the Side and who accepted.
  def beat
    line = instrument.beat

    {
      line: line.line,
      portrait: portrait(line)
    }
  end

  # The back does not move. Everything the Team knew it still knows, and the
  # Docket already folds the Acceptance in as one of the acts with no cost.
  def back = back_of_file(case_file, docket)
end
