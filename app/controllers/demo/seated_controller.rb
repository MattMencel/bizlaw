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
  end
end
