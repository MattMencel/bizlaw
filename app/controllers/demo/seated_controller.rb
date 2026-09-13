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
    # The Instructor is seated and has no page. They are not in the dispute, so
    # there is no draft to render them and no half of theirs to spend; the
    # surface for the one act they take arrives with the control that grants it,
    # and until then this is a seat the resolver knows and the routes do not
    # serve.
    def resolve
      seated = Seat.for(Seed.simulation(params[:run]), params[:seat])
      return seated if seated.seated?

      no_page
    rescue ArgumentError
      no_page
    end

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

    # A spend redirects rather than rendering, so the whole instrument is
    # re-read against what the write left behind — the slip, the Docket and the
    # front matter move together, or the page tells three stories about one act.
    def draft_path(seated) = demo_run_path(run: params[:run], seat: canonical(seated))

    def canonical(seated) = (seated.segment unless seated.segment == Seat::DEFAULT)

    # A refusal this seat is owed, and nobody else's.
    #
    # The flash is the session, and the session is the browser — so the two tabs
    # the demo is played from share it. A refusal left unscoped is read by
    # whichever tab navigates first, which stamps the wrong Side's board *and*
    # takes the sentence away from the tab that earned it. Scoped, the worst
    # that race can do is lose it, and a refusal that writes nothing anywhere is
    # something a page can afford to lose.
    def refusal_for(seated)
      carried = flash[:spend_refusal]
      carried if carried && carried["seat"] == seated.segment
    end
  end
end
