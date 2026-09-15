# frozen_string_literal: true

module Demo
  # What every demo request needs before it can do anything: the run the URL
  # names, the seat reading it, and the Day that Team is sitting in.
  #
  # A base class rather than a concern, because there is nothing else these
  # controllers are — and because the resolution rules are the one thing that
  # must not fork between reading a Day and acting on it. A seat the page
  # refuses to render and a seat a spend accepts would be two answers to the
  # question the address exists to ask.
  class SeatedController < InertiaController
    # Where a refusal waits for the seat that earned it — one shelf per act per
    # seat, named by both.
    #
    # By act, because a refused spend stamps the Action line it names while a
    # refused staging belongs to the sheet and names nothing: one shelf holding
    # both would have a spend's refusal swept by a staging that had nothing to do
    # with it.
    #
    # By seat, because the session is the browser and the demo is played from two
    # tabs. #363 put the seat in the payload instead and had the reader match on
    # it, on the grounds that a second key would be a second place for that name
    # to be wrong — but the key is derived from the same `seated.segment`, so
    # there is no second place, and one shelf for two seats means the second tab
    # to be refused *overwrites* the first tab's sentence before it has followed
    # its own redirect. That reasoning was sound while one act could be refused
    # and one tab could write; this PR made both of those two.
    SPEND_REFUSAL = "spend_refusal"
    DRAFT_REFUSAL = "draft_refusal"
    # The commit's own, and it is a third shelf rather than the draft's for the
    # reason the draft's is not the spend's: the two land in different places on
    # the page. A staging's refusal belongs to the sheet; a commit's belongs to
    # the countersignature block, which is the control that was pressed and the
    # only part of the instrument that can say what happened to it.
    COMMIT_REFUSAL = "commit_refusal"
    # The Acceptance's, and a fourth for the reason the third was a third: it
    # lands somewhere else again. The acceptance block is the other Side's paper
    # on this page, and it is the only part of the instrument that can say what
    # happened to an act taken on it.
    ACCEPTANCE_REFUSAL = "acceptance_refusal"
    # The Instructor's. Their seat names it like any other, which is what keeps
    # a Day that closed under the minute from writing a sentence onto a
    # student's page.
    WAIVER_REFUSAL = "waiver_refusal"

    private

    # `Demo::Seed.simulation` and `Demo::Seat` are the resolvers rather than
    # lookups written here: each already documents itself as the one place a
    # screen asks its question, and a run's name and a seat's are both stable
    # across resets where the rows underneath are not.
    #
    # An unknown run or seat is a 404. An Organization that does not hold the
    # pair raises instead, and that error is left to surface — it says to re-run
    # `rake demo:seed`, which is the fix, and a 404 would hide it behind "not
    # found" on a laptop where the fix is one command.
    #
    # The Instructor has no draft. They are not in the dispute, so there is
    # nothing of theirs to render here and no half of theirs to spend — their
    # one act is the waiver, and it has an instrument of its own. An address
    # spelling out their seat on a Team's surface is a reader asking for a page
    # that does not exist, which is a 404 like any other.
    def resolve
      seated = seat_at(params[:seat])
      return seated if seated.seated?

      no_page
    rescue ArgumentError
      no_page
    end

    # The Instructor, resolved by the constant rather than by what the address
    # spelled. Their routes name the segment outright, so there is nothing here
    # to read off the request: the minute is the Instructor's instrument, and a
    # seat parameter that could say otherwise would be a second authority on who
    # is looking at it.
    def resolve_instructor = seat_at(Seat::INSTRUCTOR)

    def seat_at(segment) = Seat.for(Seed.simulation(params[:run]), segment)

    # The two ways there is nothing here: a run or a seat the seed did not lay
    # down, and the Instructor, who is seated and is not in the dispute.
    def no_page
      head :not_found
      nil
    end

    # The Day the Team is sitting in. It falls back to the last Day rather than
    # failing, so a run played to its end still renders a page — and so a spend
    # into it is refused by `Days::Command` for the Day being closed, which is
    # the sentence a student should read, rather than by a route that cannot
    # find a Day to name.
    def sitting_day(simulation)
      simulation.days.where(closed_at: nil).order(:ordinal).first ||
        simulation.days.order(:ordinal).last
    end

    # The Day an act was quoted against — named by the request rather than
    # resolved a second time.
    #
    # `sitting_day` answers *which Day is this Team in*, and between the read
    # that priced a control and the write that confirms it, that answer can
    # move: the other Side commits, a deadline fires, an Instructor force-closes
    # — and the Day the student read is closed while the next one is open, with
    # a Budget of its own and a landing Day one further out. Asking the same
    # question twice would charge him against a Day he never saw.
    #
    # So the page sends the Day it was priced on and the seam judges it. A Day
    # that has since closed is already `the_day_has_closed` and a Day that has
    # not opened is already `the_day_has_not_opened`; both are sentences the
    # slip knows how to render, which is why this needs no guard of its own. An
    # ordinal off the Simulation's calendar is nobody's Day and is the caller's
    # doing, so it reads as a 404 like a mistyped seat.
    #
    # It is deliberately not bound to `sitting_day`, and does not need to be:
    # `Days::Open` writes a Day's Budget only as the Day before it closes, so of
    # a Simulation's Days exactly one is ever both unclosed and budgeted. Every
    # other ordinal is one of the two refusals above already. Checking it here
    # would put a second authority on which Days a Team may act beside the seam
    # that owns the question.
    def quoted_day(seated)
      seated.side.simulation.days.find_by(ordinal: params[:day])
    end

    # Where the slip posts, and where a spend sends the reader back to. Built
    # here rather than in `WorkingDraft`, because a path is routing and that
    # read is domain: it turns Days into ordinals and refusals into sentences
    # and has no business knowing this app has URLs.
    #
    # Both are written from the seat the resolver settled on rather than from
    # the segment the address happened to carry, and both drop it where it is
    # the default — so one seat has one address however it was reached. That is
    # two things at once: the two forms of the player's address render the same
    # prop tree rather than differing by an endpoint, and #360's bare form stays
    # his, instead of being spelled out from under him by the first act he
    # takes.
    def spend_path(seated) = demo_run_spends_path(run: params[:run], seat: canonical(seated))

    def offer_path(seated) = demo_run_offers_path(run: params[:run], seat: canonical(seated))

    # Where executing the draft posts. It is the seat's like the other two, and
    # not the Instructor's: the waiver releases the gate, but the act is still
    # the Team's own and is attributed to the member who presses it.
    def commit_path(seated) = demo_run_commits_path(run: params[:run], seat: canonical(seated))

    # Where taking their deal posts. The seat's own, like the other three: the
    # Acceptance is attributed to the member who takes it, and the teammate it
    # names countersigns rather than presses.
    def acceptance_path(seated)
      demo_run_acceptances_path(run: params[:run], seat: canonical(seated))
    end

    # A spend redirects rather than rendering, so the whole instrument is
    # re-read against what the write left behind — the slip, the Docket and the
    # front matter move together, or the page tells three stories about one act.
    def draft_path(seated) = demo_run_path(run: params[:run], seat: canonical(seated))

    # The Instructor's two. They carry no seat: the minute is addressed by the
    # seat it belongs to and there is only ever one person at it, so spelling it
    # out a second time in a path built from the same constant would be two
    # places for one name to be wrong.
    def minute_path = demo_run_minute_path(run: params[:run])

    def waiver_path = demo_run_waivers_path(run: params[:run])

    def canonical(seated) = (seated.segment unless seated.segment == Seat::DEFAULT)

    # A refusal this seat is owed, and nobody else's — taken off that seat's own
    # shelf and cleared on the way past, so it is read exactly once.
    #
    # The session is the browser, and the demo is played from two tabs, so both
    # seats share it. The flash is the obvious carrier and the wrong one: it is
    # swept by *whichever* request comes next, so the other tab navigating in
    # the window between the POST and its own redirect takes the sentence away
    # from the tab that earned it — without ever being the tab that wanted it.
    #
    # A shelf named by the seat has no such window in either direction. The other
    # tab never reads this one and never writes over it, however long either
    # round trip takes. What is left behind is bounded to one entry per act per
    # seat, overwritten only by that seat's next refusal of that act.
    def refusal_for(act, seated)
      session.delete(shelf(act, seated))
    end

    # Put one on the shelf. The seat names the shelf rather than riding in the
    # payload, so a refusal cannot be read by the wrong seat or erased by it.
    def carry_refusal(act, seated, payload)
      session[shelf(act, seated)] = payload
    end

    # The player's seat resolves from an address that may or may not spell it
    # out, so the shelf is named from the seat the resolver settled on — the same
    # value `canonical` writes his URL from. One seat, one shelf, however the
    # address reached it.
    def shelf(act, seated) = "#{act}:#{seated.segment}"
  end
end
