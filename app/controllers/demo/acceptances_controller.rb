# frozen_string_literal: true

module Demo
  # Taking the other Side's deal — the last act in the game, and the only one
  # that ends it.
  #
  # It costs nothing, which is why there is no quote and no price on the wire:
  # `Offers::Accept` sits beside `Days::Command` for the same reason staging
  # does. What it carries instead is *which instrument*, named by the Day the
  # other Side committed it on — one Offer per Side per Day by unique index, and
  # an ordinal survives the `demo:seed` reset that moves every id. So the press
  # takes the paper the reader actually read, even if a newer Offer has landed
  # since, which is legal play rather than a race: an Offer stands on the table
  # until it is taken or the run ends.
  #
  # It names a seconder, and the commit does not. That is not two rules: "one
  # attributed plaintiff, forever" leaves `seconders_other_than` empty on the
  # player's page, so a control naming a teammate there would be one no reader
  # could open. The defendant's Side has two members who have both acted, which
  # makes this the one act in the demo where the Second is *satisfied* rather
  # than waived — and the name is validated by `Second.satisfied?` against the
  # Team's own roster, so an email nobody on it answers to is a refusal and
  # never a signature.
  #
  # It is the most irreversible act on the board and the cheapest to reach, so
  # it confirms in place like the spend and the commit. What the stub prints
  # where theirs print a price is the consequence: the Day this closes, and that
  # there is nothing after it.
  class AcceptancesController < SeatedController
    def create
      seated = resolve
      return if performed?

      day = quoted_day(seated)
      return no_page if day.nil?

      Offers::Accept.call(
        offer: their_offer(seated),
        side: seated.side,
        day: day,
        by: seated.user,
        seconded_by: seconder(seated)
      )

      redirect_to draft_path(seated)
    rescue Offers::DayClosed
      refuse(seated, :the_day_has_closed)
    rescue Offers::NotSeconded
      refuse(seated, :the_acceptance_has_not_been_seconded)
    rescue Simulation::AlreadySettled
      refuse(seated, :the_matter_has_already_settled)
    rescue ArgumentError
      # A Day the other Side committed nothing on, a seconder nobody answers
      # to, an Offer this Team put on the table itself. Each is a caller with a
      # menu the register never offered rather than a refusal a student should
      # see: the block is drawn from `TermsBoard#their_offer` and names its own
      # eligible teammates. So it reads as a 404, like a mistyped seat.
      no_page
    end

    private

    # The two races the block cannot rule out — the Day ended under the reader,
    # or the matter settled across the table — plus the gate, which it can see
    # and which a page held open long enough can still lose. Each is already a
    # refusal the engine names, so it comes back as the engine's own symbol on
    # this seat's own shelf and becomes a sentence in `WorkingDraft`.
    def refuse(seated, reason)
      carry_refusal(ACCEPTANCE_REFUSAL, seated, {"reason" => reason.to_s})
      redirect_to draft_path(seated)
    end

    # The instrument being taken, resolved from the other Side and the Day it
    # was committed on. Scoped to the opponent, so the one thing this cannot
    # reach is the Team's own paper — `Offers::Accept` refuses that too, and
    # holding it here as well means the request never has to.
    def their_offer(seated)
      seated.side.opponent.committed_offers
        .joins(:day).find_by(days: {ordinal: params[:committed_on]}) ||
        raise(ArgumentError, "no Offer was committed on Day #{params[:committed_on].inspect}")
    end

    # The teammate countersigning, by the one thing about a person that is
    # stable across a `demo:seed` reset. A name cannot come back over the wire —
    # two members could share one — and a row id moves.
    #
    # `nil` where the block sent nobody, which is the state a waiver answers:
    # `Second.satisfied?` reads the waiver off the Side and the Day, so an
    # Acceptance that lands through one carries no seconder at all.
    def seconder(seated)
      named = params[:seconded_by].presence
      return nil if named.nil?

      seated.side.members.find_by(email: named) ||
        raise(ArgumentError, "#{named.inspect} is not on this Team")
    end
  end
end
