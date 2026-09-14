# frozen_string_literal: true

# Everything a Team does with an Offer before it lands, and the Instructor's
# release of the gate it lands through.
#
# These sit beside `Days::Command` rather than inside it, for the reason
# `Days::Commit` does: `Command`'s two verbs exist to confirm a spend — a cost,
# a half, what is left today and the Day the result lands — and staging has none
# of them. Staging, revising and discarding cost nothing and write no Docket
# row. Committing an Offer *is* a spend and belongs in `Command` when it is
# built.
module Offers
  # Raised when a Team reaches for a Day the Instructor's deadline or
  # force-close has already ended. Staging into it would be a draft nobody can
  # commit against a Budget that has already expired.
  DayClosed = Class.new(StandardError)

  # Raised when a Team stages onto a Day whose Offer it has already committed.
  # `Days::Command` refuses the second commit with
  # `an_offer_has_already_been_committed_today`, and this is the same rule at the
  # other end of it: a draft revised after the commit it was copied from is a
  # position nobody can execute, and `TermsBoard#ours` prefers the draft — so the
  # executed instrument would print terms over two countersignatures that never
  # signed them. The Day stays open until the other Side commits, which is the
  # whole window this closes.
  AlreadyCommitted = Class.new(StandardError)

  # Raised when an Acceptance reaches the seam without the teammate's
  # confirmation the gate is made of, and without the Instructor's waiver of it.
  # The commit's refusal is a `Days::Command::Refused` instead, because that one
  # has a price to quote alongside the reason.
  NotSeconded = Class.new(StandardError)
end
