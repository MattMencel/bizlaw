# frozen_string_literal: true

module Demo
  # Drawing the position: the Terms, the Exhibits riding them and the covering
  # note, arriving together and replacing what was on the Team's table.
  #
  # Unlike a spend there is nothing to confirm and nothing to quote. Staging
  # costs nothing, writes no Docket row and is ungated — `Offers::Stage` is the
  # only path a position reaches the table, and the whole of what it refuses is a
  # Day that has ended. So the page posts the position and is sent back to read
  # it, with no price crossing the wire in either direction.
  #
  # It is one act rather than one per field. A teammate Seconds a *position*, and
  # a position that reshaped itself under them while they read it is the thing
  # the Second exists to prevent; it also keeps the Docket's `offer_staged` line
  # meaning one drawing rather than one keystroke.
  #
  # What the sheet sends is the Case's own vocabulary and the Case File's own
  # identifiers, never row ids. Both are stable across the `demo:seed` reset that
  # moves every id underneath them, and both are what the engine already names
  # these things by.
  class OffersController < SeatedController
    def create
      seated = resolve
      return if performed?

      day = quoted_day(seated)
      return no_page if day.nil?

      Offers::Stage.call(
        side: seated.side,
        day: day,
        by: seated.user,
        terms: terms_drawn,
        exhibits: exhibits_clipped(seated),
        note: params[:note].presence
      )

      redirect_to draft_path(seated)
    rescue Offers::DayClosed
      refuse(seated, :the_day_has_closed)
    rescue Simulation::AlreadySettled
      refuse(seated, :the_simulation_has_settled)
    rescue ArgumentError
      # A Term the Case never authored, an Exhibit this Team cannot play, an
      # Offer naming nothing at all — each is a caller with a menu the engine
      # never offered rather than a refusal a student should see. The sheet
      # cannot produce any of them: it renders the authored vocabulary, offers
      # only the Team's own playable documents, and holds its control dead while
      # no Term is checked. So it reads as a 404, like a mistyped seat.
      no_page
    end

    private

    # The two races the sheet cannot rule out. Both are already refusals the
    # engine names — the Day the Team was drafting on ended between the page and
    # the press — so they come back as the engine's own symbols on the shelf and
    # become sentences in `WorkingDraft`, the one place in this app that knows
    # what a refusal reads like. The demo is played from two tabs, which is
    # exactly where a Day closes under somebody.
    def refuse(seated, reason)
      carry_refusal(DRAFT_REFUSAL, seated, {"reason" => reason.to_s})
      redirect_to draft_path(seated)
    end

    # The position, as `Offers::Stage` takes it: every Term the Team has written
    # in, mapped to money's amount in cents and every other Term to nil. A Term
    # left off the sheet is simply absent from the Hash — an offer of nothing is
    # a position somebody took, and leaving it out is what says nobody did.
    #
    # A Term arrives named and nothing else, because a Term carries no settings:
    # they are atomic, so being on the sheet is the whole of what there is to
    # say about six of the seven. The seventh carries the figure, which arrives
    # in dollars because that is what a student typed and is converted here, at
    # the boundary, so the amount and the format it was written in never travel
    # together past this line.
    #
    # A key the Case never authored falls to `Offers::Stage`, which is the one
    # seam a position reaches the table through and stays the authority on its
    # own vocabulary. Checking it again here would be a second place for the
    # answer to be wrong.
    def terms_drawn
      named(:terms).to_h do |key|
        [key, (key == CaseTerm::MONEY) ? cents(params[:amount]) : nil]
      end
    end

    # A list of names, however the request spelled an empty one. An Inertia
    # visit posts JSON and an empty list stays a list, but a form-encoded post
    # collapses it to the empty string — and a blank is the absence of a name
    # rather than a name nothing answers to, which is the difference between
    # taking every Exhibit off the draft and a 404.
    def named(key) = Array(params[key]).map(&:to_s).compact_blank.uniq

    # Whole dollars or a decimal figure, as typed, with the separators a student
    # may have written it with. Anything else is not something a field that
    # accepts an amount can have produced, so it is the caller's doing.
    def cents(typed)
      figure = typed.to_s.delete(",$ ").presence
      raise ArgumentError, "an offer of money is worth an amount" if figure.nil?
      raise ArgumentError, "#{typed.inspect} is not an amount" unless /\A\d+(\.\d{1,2})?\z/.match?(figure)

      (BigDecimal(figure) * 100).to_i
    end

    # The Case File rows the Exhibits ride out of — this Team's own, which is
    # what `staged_offer_exhibits` keys by `(id, side_id)` to enforce. Named by
    # the authored identifier and resolved against the Side, so a document out of
    # the other Team's folder cannot be reached from here at all.
    def exhibits_clipped(seated)
      clipped = named(:exhibits)
      return [] if clipped.empty?

      held = seated.side.case_file_documents.joins(:case_document)
        .where(case_documents: {identifier: clipped})
      raise ArgumentError, clipped.join(", ") unless held.size == clipped.size

      held.to_a
    end
  end
end
