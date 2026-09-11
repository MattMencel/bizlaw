# frozen_string_literal: true

module Demo
  # The demo's one screen. The URL names a run and a seat, and the seat is
  # optional: #332 settled that the player is the plaintiff, alone, so the bare
  # form is his and the two seeded runs resolve to the Day each was laid down to
  # open on without anything to choose between.
  #
  # The seat is what the second tab needs. There is no authentication, no
  # session and no `Current.user`, and every seam in the Day takes a `by:` — so
  # the address is the whole of what says who is reading, and `Demo::Seat`
  # answers it. Nothing is held between requests: the pair is resolved from the
  # URL each time, which is why two tabs can be two people without either one
  # standing on the other.
  class RunsController < InertiaController
    def show
      seated = resolve
      return if performed?

      render inertia: "Demo/WorkingDraft",
        props: WorkingDraft.for(
          seated.side, day: sitting_day(seated.side.simulation), you: seated.user
        ).to_props
    end

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
    # there is no draft to render them; the surface for the one act they take
    # arrives with the control that grants it, and until then this is a seat the
    # resolver knows and the route does not serve.
    def resolve
      seated = Seat.for(Seed.simulation(params[:run]), params[:seat])
      return seated if seated.seated?

      head :not_found
      nil
    rescue ArgumentError
      head :not_found
      nil
    end

    # The Day the Team is sitting in. It falls back to the last Day rather than
    # failing, so a run played to its end still renders a page.
    def sitting_day(simulation)
      simulation.days.where(closed_at: nil).order(:ordinal).first ||
        simulation.days.order(:ordinal).last
    end
  end
end
