# frozen_string_literal: true

module Demo
  # The Instructor's page — the one surface in the demo that is not a Team's
  # file.
  #
  # It resolves its reader from the constant rather than from the address, which
  # is the whole difference between this and `RunsController`: a run's screen is
  # read by whoever the URL names, and this one is read by the Instructor
  # because the route *is* the Instructor's. There is nothing here for a seat
  # parameter to say.
  #
  # The Day is the sitting one, and there is no picker. `CONTEXT.md` § Instructor
  # keeps their powers over a running Simulation deliberately few, and a waiver
  # is granted for the Day it is granted on — reaching into a Day nobody is
  # playing is not one of them.
  class MinutesController < SeatedController
    def show
      instructor = resolve_instructor
      simulation = Seed.simulation(params[:run])

      render inertia: "Demo/Minute",
        props: Minute.for(
          simulation,
          day: sitting_day(simulation),
          you: instructor.user,
          refused: refusal_for(WAIVER_REFUSAL, instructor)
        ).to_props.merge(waiver_path: waiver_path)
    rescue ArgumentError
      no_page
    end
  end
end
