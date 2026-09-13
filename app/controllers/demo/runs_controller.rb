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
  class RunsController < SeatedController
    def show
      seated = resolve
      return if performed?

      render inertia: "Demo/WorkingDraft",
        props: WorkingDraft.for(
          seated.side,
          day: sitting_day(seated.side.simulation),
          you: seated.user,
          refused: refusal_for(seated)
        ).to_props.merge(spend_path: spend_path(seated))
    end
  end
end
