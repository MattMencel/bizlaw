# frozen_string_literal: true

module Demo
  # Executing the draft: the Team puts its staged position on the table for one
  # point of the exchange half plus the Case's Exhibit price for each Exhibit
  # riding it, and its Day is committed with it.
  #
  # It is the second act on `Days::Command` and the shape is the spend's: a Day
  # and no price, because `apply` builds its own quote inside the request that
  # charges. What it does **not** carry is the position — `Command` re-reads the
  # table inside the charge's own transaction, so a draft revised between the
  # render and the press is charged for what actually lands rather than for what
  # the page last printed.
  #
  # It names no seconder. The only thing that opens the gate on this map is the
  # Instructor's waiver, and `Second.satisfied?` reads that from the Side and the
  # Day rather than from anything a page could send — so there is nothing here to
  # say. A commit that lands under a waiver carries no seconder at all, which is
  # what keeps Attribution from naming someone who did not take the position.
  #
  # It is irreversible and it can end the Day: a commit implies the Day commit,
  # and on a Day the other Side has already committed, `Days::Close` runs inside
  # the same transaction. The page it redirects to is therefore sometimes the
  # *next* Day, which is the engine being honest rather than a redirect going
  # wrong.
  class CommitsController < SeatedController
    def create
      seated = resolve
      return if performed?

      day = quoted_day(seated)
      return no_page if day.nil?

      Days::Command.apply(
        act: :commit_offer, side: seated.side, day: day, by: seated.user, seconded_by: nil
      )

      redirect_to draft_path(seated)
    rescue Days::Command::Refused => e
      # A bare reason, like the staging's: there is only one draft to execute, so
      # naming which one was refused would be naming the only one there is.
      #
      # It has to be carried rather than left to the block's own live quote,
      # because the one refusal this race actually produces —
      # `an_offer_has_already_been_committed_today` — makes `committed` non-nil,
      # and the block stops asking for a quote the moment it becomes a record. A
      # reader who pressed Execute would get back an executed instrument he did
      # not execute, with nothing on the page saying so.
      carry_refusal(COMMIT_REFUSAL, seated, {"reason" => e.quote.refusal.to_s})
      redirect_to draft_path(seated)
    rescue ArgumentError
      no_page
    end
  end
end
