# frozen_string_literal: true

module Demo
  # The demo's one screen. The URL names a run and nothing else — no Side, no
  # Day — because #332 settled that the player is the plaintiff, alone, and the
  # two seeded runs then resolve to the Day each was laid down to open on
  # without anything to choose between.
  class RunsController < InertiaController
    def show
      simulation = resolve(params[:run])
      return if performed?

      render inertia: "Demo/WorkingDraft",
        props: WorkingDraft.for(
          simulation.plaintiff_side, day: sitting_day(simulation)
        ).to_props
    end

    private

    # `Demo::Seed.simulation` is the resolver rather than a lookup written here:
    # it already documents itself as the one place a screen asks which
    # Simulation a demo URL names, and a run's name is stable across resets
    # where its id is not.
    #
    # An unknown name is a 404. An Organization that does not hold the pair
    # raises instead, and that error is left to surface — it says to re-run
    # `rake demo:seed`, which is the fix, and a 404 would hide it behind "not
    # found" on a laptop where the fix is one command.
    def resolve(run)
      Demo::Seed.simulation(run)
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
